import SwiftUI

struct RecipeCard: View {
    let recipe: Recipe
    var compact = false

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Group {
                if let data = recipe.imageData, let image = UIImage(data: data) {
                    Image(uiImage: image).resizable().scaledToFill()
                } else {
                    ZStack {
                        SazliTheme.olive.opacity(0.12)
                        Image(systemName: recipe.recipeCategory.symbol)
                            .font(.title).foregroundStyle(SazliTheme.olive)
                    }
                }
            }
            .frame(width: compact ? 56 : 84, height: compact ? 72 : 100)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 9) {
                Text(recipe.recipeCategory.title.uppercased())
                    .font(.caption2.weight(.semibold)).tracking(1.1)
                    .foregroundStyle(SazliTheme.terracotta)
                Text(recipe.title).font(.headline).foregroundStyle(.primary)
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) { metadata }
                    VStack(alignment: .leading, spacing: 8) { metadata }
                }
                .font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if recipe.isFavorite {
                Image(systemName: "heart.fill").foregroundStyle(SazliTheme.terracotta)
                    .accessibilityLabel("Favorite")
            }
        }
        .padding(14)
        .background(SazliTheme.surface, in: RoundedRectangle(cornerRadius: 24))
        .contentShape(RoundedRectangle(cornerRadius: 24))
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private var metadata: some View {
        Label(recipe.preparationTime > 0 ? "\(recipe.preparationTime) min" : "Time not set", systemImage: "clock")
        if recipe.rating > 0 {
            Label("\(recipe.rating)/5", systemImage: "star.fill")
        } else {
            Text("Not rated")
        }
    }
}
