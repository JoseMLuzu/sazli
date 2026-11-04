import SwiftUI

struct RecipeCard: View {
    let recipe: Recipe
    @ScaledMetric(relativeTo: .headline) private var cardHeight: CGFloat = 180

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                RecipeThumbnail(recipe: recipe)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                LinearGradient(
                    stops: [.init(color: .black.opacity(0.68), location: 0),
                            .init(color: .black.opacity(0.08), location: 0.55),
                            .init(color: .black.opacity(0.24), location: 1)],
                    startPoint: .top, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 6) {
                        Text(recipe.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
                        if recipe.isFavorite {
                            Image(systemName: "heart.fill")
                                .font(.caption).foregroundStyle(SazliTheme.coral)
                        }
                    }
                    if recipe.rating > 0 {
                        Label {
                            Text("\(recipe.rating)/5").foregroundStyle(.white)
                        } icon: {
                            Image(systemName: "star.fill").foregroundStyle(SazliTheme.orange)
                        }
                        .font(.caption2.weight(.semibold))
                    }
                    Spacer(minLength: 8)
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 8) { metadata }
                        VStack(alignment: .leading, spacing: 6) { metadata }
                    }
                    .font(.caption2.weight(.semibold))
                    .labelStyle(.titleAndIcon)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 9).padding(.vertical, 7)
                    .background(SazliTheme.background.opacity(0.96), in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(12)
            }
        }
        .frame(height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .contentShape(RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    @ViewBuilder private var metadata: some View {
        Label("\(recipe.servings)", systemImage: "person.2.fill")
            .monospacedDigit()
        Label(recipe.preparationTime > 0 ? "\(recipe.preparationTime) min" : "—", systemImage: "clock")
            .monospacedDigit()
    }

    private var accessibilitySummary: String {
        let time = recipe.preparationTime > 0 ? "\(recipe.preparationTime) minutes" : "Preparation time not set"
        let rating = recipe.rating > 0 ? "\(recipe.rating) of 5 stars" : "Not rated"
        let servings = "\(recipe.servings) \(recipe.servings == 1 ? "serving" : "servings")"
        return "\(recipe.title), \(recipe.recipeCategory.title), \(servings), \(time), \(rating)\(recipe.isFavorite ? ", Favorite" : "")"
    }
}
