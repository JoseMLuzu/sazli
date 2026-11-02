import Foundation
import ImageIO
import UniformTypeIdentifiers

enum RecipePhoto {
    // Decode a thumbnail instead of allocating a full-resolution camera image.
    static func prepare(_ data: Data) throws -> Data {
        guard data.count <= 30_000_000,
              let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 1800
              ] as CFDictionary) else { throw PhotoError.unreadable }
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil)
        else { throw PhotoError.unreadable }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.82] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw PhotoError.unreadable }
        return output as Data
    }

    enum PhotoError: LocalizedError {
        case unreadable
        var errorDescription: String? { "This photo couldn't be loaded. Please choose an image smaller than 30 MB." }
    }
}
