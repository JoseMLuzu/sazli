import SwiftUI

struct RecipeThumbnail: View {
    let recipe: Recipe
    @Environment(\.displayScale) private var displayScale
    @State private var image: UIImage?

    private struct Request: Equatable {
        let id: UUID
        let revision: Date
        let pixels: Int
    }

    var body: some View {
        GeometryReader { geometry in
            let request = Request(id: recipe.id, revision: recipe.updatedAt,
                                  pixels: RecipeThumbnailCache.pixelSize(Int(
                                    max(geometry.size.width, geometry.size.height) * displayScale)))
            ZStack {
                LinearGradient(colors: [SazliTheme.olive, SazliTheme.orange],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                if let image {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    Image(systemName: recipe.recipeCategory.symbol)
                        .font(.system(size: 64, weight: .ultraLight))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
            .task(id: request) {
                image = nil
                guard let data = recipe.imageData else { return }
                let loaded = await RecipeThumbnailCache.shared.image(
                    id: request.id, data: data, pixels: request.pixels)
                guard !Task.isCancelled else { return }
                image = loaded
            }
        }
    }
}
