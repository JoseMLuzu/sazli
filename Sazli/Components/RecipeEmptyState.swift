import SwiftUI

struct RecipeEmptyState: View {
    var isSearching = false
    let addRecipe: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: isSearching ? "magnifyingglass" : "book.closed")
                .font(.system(size: 38, weight: .light))
                .foregroundStyle(SazliTheme.terracotta)
                .frame(width: 96, height: 96)
                .background(SazliTheme.terracotta.opacity(0.09), in: RoundedRectangle(cornerRadius: 30))
                .accessibilityHidden(true)
            Text(isSearching ? "Nothing here just yet" : "Good food starts here")
                .font(.title2.weight(.semibold))
            Text(isSearching ? "Try another name, ingredient, or filter to find a recipe." : "Save a family favorite, a new discovery, or just a link for later.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if !isSearching {
                Button("Save your first recipe", action: addRecipe)
                    .font(.headline).buttonStyle(.bordered).tint(SazliTheme.terracotta)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity)
    }
}
