import SwiftData
import SwiftUI

struct RecipeDetailView: View {
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @Environment(\.modelContext) private var context
  @Environment(\.dismiss) private var dismiss
  @Environment(\.openURL) private var openURL
  let recipe: Recipe
  var onDelete: (() -> Void)? = nil
  var onDuplicate: ((UUID) -> Void)? = nil
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
    .navigationTitle("").navigationBarTitleDisplayMode(.inline)
    .toolbarBackground(SazliTheme.background, for: .navigationBar)
    .toolbarBackground(.visible, for: .navigationBar)
    .toolbar {
      ToolbarItemGroup(placement: .topBarTrailing) {
        Button(action: toggleFavorite) {
          Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
        }
        .accessibilityLabel(recipe.isFavorite ? "Remove from favorites" : "Add to favorites")
        Menu {
          Button { showingEditor = true } label: {
            Label("Edit recipe", systemImage: "pencil")
          }
          Button { showingRating = true } label: {
            Label("Rating & notes", systemImage: "star")
          }
          Button(action: duplicate) {
            Label("Duplicate recipe", systemImage: "doc.on.doc")
          }
          ShareLink(item: RecipeSharing.text(for: recipe), subject: Text(recipe.title)) {
            Label("Share recipe", systemImage: "square.and.arrow.up")
          }
          Divider()
          Button(role: .destructive) { confirmingDelete = true } label: {
            Label("Delete recipe", systemImage: "trash")
          }
        } label: {
          Image(systemName: "ellipsis")
        }
        .accessibilityLabel("Recipe options")
      }
    }
    .safeAreaInset(edge: .bottom) {
      Group {
        if recipe.instructionLines.isEmpty {
          PrimaryButton(title: "Add preparation steps", symbol: "pencil") { showingEditor = true }
        } else {
          PrimaryButton(title: "Start cooking", symbol: "fork.knife") { showingCooking = true }
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

    return VStack(alignment: .leading, spacing: 28) {
      if recipe.imageData != nil {
        RecipeThumbnail(recipe: recipe)
        .frame(height: min(max(width * 0.6, 200), 320))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Photo of \(recipe.title)")
        .accessibilityAddTraits(.isImage)
      }
      introduction
      layout {
        ingredientsCard
        methodSection
      }
      notesCard
      if let url = SourceLink.url(from: recipe.sourceURL) {
        sourceCard(url)
      }
    }
  }

  private var ingredientsCard: some View {
    VStack(alignment: .leading, spacing: 14) {
      RecipeSectionHeading(
        title: "Ingredients",
        subtitle: "For \(recipe.servings) \(recipe.servings == 1 ? "serving" : "servings")",
        symbol: "leaf.fill", tint: SazliTheme.olive, showsIcon: false)
      VStack(alignment: .leading, spacing: 0) {
        if recipe.ingredientLines.isEmpty {
          emptyText("Add ingredients when you're ready to make this recipe.")
            .padding(.vertical, 8)
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
      .padding(.horizontal, 18).padding(.vertical, 8)
      .frame(maxWidth: .infinity, alignment: .leading)
      .recipePanel(cornerRadius: 20)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .contain)
  }

  private var methodSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      RecipeSectionHeading(
        title: "Method",
        subtitle: recipe.instructionLines.isEmpty ? "No steps added yet"
          : "\(recipe.instructionLines.count) \(recipe.instructionLines.count == 1 ? "step" : "steps")",
        symbol: "list.number", showsIcon: false)
      if recipe.instructionLines.isEmpty {
        emptyText("Your steps will appear here. Edit this recipe to add them.")
          .padding(18).frame(maxWidth: .infinity, alignment: .leading).recipePanel(cornerRadius: 20)
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
      HStack(spacing: 12) {
        Image(systemName: "link")
          .font(.body).foregroundStyle(SazliTheme.terracotta)
          .frame(width: 24)
          .accessibilityHidden(true)
        VStack(alignment: .leading, spacing: 5) {
          Text("Original recipe · \(recipe.platform.title)").font(.subheadline.weight(.semibold))
          Text(url.host ?? recipe.sourceURL).font(.caption).foregroundStyle(.secondary)
            .lineLimit(2)
        }
        Spacer()
        Image(systemName: "arrow.up.right")
          .font(.caption.weight(.semibold)).foregroundStyle(SazliTheme.terracotta)
          .accessibilityHidden(true)
      }
      .padding(18).recipePanel(cornerRadius: 20)
    }
    .buttonStyle(.plain)
    .accessibilityHint("Opens the original recipe link.")
  }

  private var notesCard: some View {
    VStack(alignment: .leading, spacing: 18) {
      Text("Rating & notes").font(.title3.weight(.semibold)).accessibilityAddTraits(.isHeader)
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
    .recipePanel(cornerRadius: 20)
    .accessibilityElement(children: .contain)
  }

  private var introduction: some View {
    VStack(alignment: .leading, spacing: 16) {
      VStack(alignment: .leading, spacing: 10) {
        Label(recipe.recipeCategory.title, systemImage: recipe.recipeCategory.symbol)
          .font(.subheadline.weight(.medium)).foregroundStyle(SazliTheme.terracotta)
        Text(recipe.title).font(.title.bold())
          .accessibilityAddTraits(.isHeader)
        if !recipe.recipeDescription.isEmpty {
          Text(recipe.recipeDescription).font(.subheadline)
            .foregroundStyle(.secondary).lineSpacing(4)
        }
      }
      let metadataLayout =
        dynamicTypeSize.isAccessibilitySize
        ? AnyLayout(VStackLayout(spacing: 10)) : AnyLayout(HStackLayout(spacing: 10))
      metadataLayout {
        RecipeInfoTile(
          value: recipe.preparationTime > 0 ? "\(recipe.preparationTime) min" : "Not set",
          title: "Preparation", symbol: "clock")
        if !dynamicTypeSize.isAccessibilitySize {
          Divider().frame(height: 32).accessibilityHidden(true)
        }
        RecipeInfoTile(
          value: "\(recipe.servings)", title: recipe.servings == 1 ? "Serving" : "Servings",
          symbol: "person.2", tint: SazliTheme.olive)
      }
      .padding(16)
      .recipePanel(cornerRadius: 20)
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

  private func duplicate() {
    do {
      let copy = try RecipeStore.duplicate(recipe, in: context)
      onDuplicate?(copy.id)
    } catch { errorMessage = "Your recipe couldn't be duplicated. " + error.localizedDescription }
  }

  private func delete() {
    do {
      try RecipeStore.delete(recipe, in: context)
      if let onDelete { onDelete() } else { dismiss() }
    } catch { errorMessage = "Your recipe couldn't be deleted. " + error.localizedDescription }
  }
}
