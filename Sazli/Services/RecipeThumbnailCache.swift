import ImageIO
import UIKit

/// Disposable display images; original photo data remains in SwiftData.
@MainActor
final class RecipeThumbnailCache {
    static let shared = RecipeThumbnailCache()

    private final class Entry {
        let data: Data
        let image: UIImage
        init(data: Data, image: UIImage) { self.data = data; self.image = image }
    }

    private let cache = NSCache<NSString, Entry>()

    init() {
        cache.countLimit = 40
        cache.totalCostLimit = 24 * 1024 * 1024
    }

    func image(id: UUID, data: Data, pixels: Int) async -> UIImage? {
        let size = Self.pixelSize(pixels)
        let key = "\(id)-\(size)" as NSString
        if let entry = cache.object(forKey: key), entry.data == data { return entry.image }
        let decoded = await Task.detached(priority: .utility) {
            Self.decode(data, pixels: size)
        }.value
        guard !Task.isCancelled, let decoded else { return nil }
        let image = UIImage(cgImage: decoded)
        cache.setObject(Entry(data: data, image: image), forKey: key,
                        cost: decoded.bytesPerRow * decoded.height + data.count)
        return image
    }

    nonisolated static func pixelSize(_ requested: Int) -> Int {
        min(1800, max(128, ((requested + 127) / 128) * 128))
    }

    nonisolated private static func decode(_ data: Data, pixels: Int) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, [
            kCGImageSourceShouldCache: false
        ] as CFDictionary) else { return nil }
        return CGImageSourceCreateThumbnailAtIndex(source, 0, [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: pixels,
            kCGImageSourceShouldCacheImmediately: true
        ] as CFDictionary)
    }
}
