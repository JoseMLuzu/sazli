import SwiftData
import SwiftUI

struct RecipeDetailView: View {
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @Environment(\.modelContext) private var context
  @Environment(\.dismiss) private var dismiss
  @Environment(\.openURL) private var openURL
  let recipe: Recipe
  var onDelete: (() -> Void)? = nil
  @State private var showingEditor = false
  @State private var showingRating = false
  @State private var showingCooking = false
  @State private var confirmingDelete = false
  @State private var errorMessage: String?

  var body: some View {
    GeometryReader { geometry in
      ScrollView {
        recipeContent(width: geometry.size.width)
          .frame(maxWidth: SazliLayout.contentWidth)
          .padding(20)
          .frame(maxWidth: .infinity, alignment: .top)
      }
    }
    .sazliScreen()
    .navigationTitle("Recipe").navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItemGroup(placement: .topBarTrailing) {
        Button(action: toggleFavorite) {
          Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
        }
        .accessibilityLabel(recipe.isFavorite ? "Remove from favorites" : "Add to favorites")
        Button("Edit") { showingEditor = true }
      }
    }
    .safeAreaInset(edge: .bottom) {
      VStack(spacing: 6) {
        PrimaryButton(title: "Let's cook", symbol: "fork.knife") { showingCooking = true }
          .disabled(recipe.instructionLines.isEmpty)
        if recipe.instructionLines.isEmpty {
          Text("Add preparation steps to start cooking.")
            .font(.caption).foregroundStyle(.secondary)
        }
      }
      .frame(maxWidth: SazliLayout.actionWidth)
      .padding(.horizontal, 20).padding(.vertical, 12)
      .frame(maxWidth: .infinity)
      .background(SazliTheme.background.opacity(0.97))
    }
    .sheet(isPresented: $showingEditor) { RecipeEditorView(recipe: recipe) }
    .sheet(isPresented: $showingRating) { RecipeRatingView(recipe: recipe) }
    .fullScreenCover(isPresented: $showingCooking) { CookingModeView(recipe: recipe) }
    .confirmationDialog(
      "Delete \(recipe.title)?", isPresented: $confirmingDelete, titleVisibility: .visible
    ) {
      Button("Delete recipe", role: .destructive) { delete() }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("This recipe, its photo, and your notes will be permanently removed.")
    }
    .alert(
      "Something went wrong",
      isPresented: Binding(
        get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
      )
    ) {
      Button("OK") { errorMessage = nil }
    } message: {
      Text(errorMessage ?? "Please try again.")
    }
  }

  private func recipeContent(width: CGFloat) -> some View {
    let layout =
      width >= SazliLayout.columnBreakpoint && !dynamicTypeSize.isAccessibilitySize
      ? AnyLayout(HStackLayout(alignment: .top, spacing: 32))
      : AnyLayout(VStackLayout(alignment: .leading, spacing: 24))

    return VStack(alignment: .leading, spacing: 24) {
      if let data = recipe.imageData, let image = UIImage(data: data) {
        Image(uiImage: image).resizable().scaledToFill()
          .frame(height: 240).frame(maxWidth: .infinity).clipped()
          .clipShape(RoundedRectangle(cornerRadius: 26))
          .accessibilityLabel("Photo of \(recipe.title)")
      }
      introduction
      if !recipe.recipeDescription.isEmpty {
        Text(recipe.recipeDescription).foregroundStyle(.secondary).lineSpacing(4)
      }
      layout {
        ingredientsCard
        methodSection
      }
      if let url = SourceLink.url(from: recipe.sourceURL) {
        sourceCard(url)
      }
      notesCard
      Button("Delete recipe", role: .destructive) { confirmingDelete = true }
        .frame(maxWidth: .infinity, minHeight: 44).padding(.top, 8)
    }
  }

  private var ingredientsCard: some View {
    VStack(alignment: .leading, spacing: 18) {
      RecipeSectionHeading(
        title: "Ingredients",
        subtitle: "For \(recipe.servings) \(recipe.servings == 1 ? "serving" : "servings")",
        symbol: "leaf.fill", tint: SazliTheme.olive)
      if recipe.ingredientLines.isEmpty {
        emptyText("Add ingredients when you're ready to make this recipe.")
      } else {
        VStack(spacing: 0) {
          ForEach(Array(recipe.ingredientLines.enumerated()), id: \.offset) { index, line in
            IngredientRow(text: line)
            if index < recipe.ingredientLines.count - 1 {
              Divider().overlay(SazliTheme.olive.opacity(0.08)).padding(.leading, 36)
            }
          }
        }
      }
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .recipePanel()
    .accessibilityElement(children: .contain)
  }

  private var methodSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      RecipeSectionHeading(
        title: "Method",
        subtitle:
          "\(recipe.instructionLines.count) \(recipe.instructionLines.count == 1 ? "step" : "steps") to follow",
        symbol: "list.number")
      if recipe.instructionLines.isEmpty {
        emptyText("Your steps will appear here. Edit this recipe to add them.")
          .padding(20).frame(maxWidth: .infinity, alignment: .leading).recipePanel()
      } else {
        LazyVStack(spacing: 12) {
          ForEach(Array(recipe.instructionLines.enumerated()), id: \.offset) { index, line in
            RecipeStepCard(number: index + 1, text: line)
          }
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .contain)
  }

  private func sourceCard(_ url: URL) -> some View {
    Button {
      openURL(url) { accepted in
        if !accepted { errorMessage = "This link couldn't be opened on your device." }
      }
    } label: {
      HStack {
        Image(systemName: "link")
          .font(.title3).foregroundStyle(SazliTheme.terracotta)
          .frame(width: 42, height: 42)
          .background(SazliTheme.terracotta.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
          .accessibilityHidden(true)
        VStack(alignment: .leading, spacing: 5) {
          Text("Original source").font(.caption).foregroundStyle(.secondary)
          Text(recipe.platform.title).font(.headline)
          Text(url.host ?? recipe.sourceURL).font(.caption).foregroundStyle(.secondary).lineLimit(2)
        }
        Spacer()
        Image(systemName: "arrow.up.right")
      }
      .padding(18).recipePanel()
    }
    .buttonStyle(.plain)
    .accessibilityHint("Opens the original recipe link.")
  }

  private var notesCard: some View {
    VStack(alignment: .leading, spacing: 18) {
      RecipeSectionHeading(
        title: "Your cooking notes", subtitle: "Make it yours, every time", symbol: "pencil.line",
        tint: SazliTheme.orange)
      let ratingLayout = dynamicTypeSize.isAccessibilitySize
        ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10))
        : AnyLayout(HStackLayout(spacing: 12))
      ratingLayout {
        RatingStars(rating: recipe.rating)
        Text(recipe.rating == 0 ? "Not rated yet" : "\(recipe.rating) / 5")
          .font(.caption).foregroundStyle(.secondary)
      }
      if !recipe.notes.isEmpty {
        Text(recipe.notes)
      } else {
        emptyText("Add a rating or a note for next time.")
      }
      if recipe.wouldCookAgain {
        Label("Would make again", systemImage: "checkmark.seal")
          .font(.subheadline.weight(.medium)).foregroundStyle(SazliTheme.olive)
      }
      Button(
        recipe.rating == 0 && recipe.notes.isEmpty ? "Rate this recipe" : "Edit rating & notes"
      ) {
        showingRating = true
      }
      .font(.subheadline.weight(.semibold))
      .buttonStyle(.bordered).tint(SazliTheme.terracotta)
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .recipePanel()
    .accessibilityElement(children: .contain)
  }

  private var introduction: some View {
    VStack(alignment: .leading, spacing: 14) {
      Label(recipe.recipeCategory.title, systemImage: recipe.recipeCategory.symbol)
        .font(.caption.weight(.semibold)).foregroundStyle(SazliTheme.terracotta)
        .padding(.horizontal, 12).padding(.vertical, 7)
        .background(SazliTheme.terracotta.opacity(0.1), in: Capsule())
      Text(recipe.title).font(.system(.largeTitle, design: .rounded, weight: .bold))
        .accessibilityAddTraits(.isHeader)
      let metadataLayout =
        dynamicTypeSize.isAccessibilitySize
        ? AnyLayout(VStackLayout(spacing: 10)) : AnyLayout(HStackLayout(spacing: 10))
      metadataLayout {
        RecipeInfoTile(
          value: recipe.preparationTime > 0 ? "\(recipe.preparationTime) min" : "Not set",
          title: "Preparation", symbol: "clock")
        RecipeInfoTile(
          value: "\(recipe.servings)", title: recipe.servings == 1 ? "Serving" : "Servings",
          symbol: "person.2", tint: SazliTheme.olive)
      }
    }
  }

  private func emptyText(_ text: String) -> some View {
    Text(text).foregroundStyle(.secondary).font(.subheadline)
  }

  private func toggleFavorite() {
    recipe.isFavorite.toggle()
    recipe.updatedAt = Date()
    do { try RecipeStore.commit(in: context) } catch {
      errorMessage = "Your favorite couldn't be saved. " + error.localizedDescription
    }
  }

  private func delete() {
    do {
      try RecipeStore.delete(recipe, in: context)
      if let onDelete { onDelete() } else { dismiss() }
    } catch { errorMessage = "Your recipe couldn't be deleted. " + error.localizedDescription }
  }
}
