import SwiftData
import SwiftUI

struct LibraryView: View {
  @Environment(\.dynamicTypeSize) private var dynamicTypeSize
  @Environment(\.scenePhase) private var scenePhase
  @Query(sort: \Recipe.createdAt, order: .reverse) private var recipes: [Recipe]
  @State private var search = ""
  @State private var filter: LibraryFilter = .all
  @State private var showingEditor = false
  @State private var showingSettings = false
  @State private var importPresentation: ImportPresentation?
  @State private var inbox = RecipeImportInbox.shared
  @State private var importError: String?
  @State private var selectedRecipeID: UUID?
  @State private var columnVisibility: NavigationSplitViewVisibility = .all
  @State private var preferredCompactColumn: NavigationSplitViewColumn = .sidebar

  private var selectedRecipe: Recipe? {
    recipes.first { $0.id == selectedRecipeID }
  }

  private var filteredRecipes: [Recipe] {
    recipes.filter { recipe in
      (search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        || recipe.title.localizedStandardContains(
          search.trimmingCharacters(in: .whitespacesAndNewlines)))
        && filter.includes(recipe)
    }
  }

  var body: some View {
    NavigationSplitView(
      columnVisibility: $columnVisibility, preferredCompactColumn: $preferredCompactColumn
    ) {
      GeometryReader { geometry in
        ScrollView {
          libraryContent(width: geometry.size.width)
            .frame(maxWidth: SazliLayout.contentWidth)
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity, alignment: .top)
        }
      }
      .sazliScreen()
      .navigationTitle("")
      .navigationBarTitleDisplayMode(.inline)
      .toolbarBackground(SazliTheme.background, for: .navigationBar)
      .toolbarBackground(.visible, for: .navigationBar)
      .navigationSplitViewColumnWidth(min: 260, ideal: 320, max: 360)
      .searchable(text: $search, prompt: "Find a recipe")
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          libraryBrand
        }
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            showingEditor = true
          } label: {
            Image(systemName: "plus").fontWeight(.semibold)
          }
          .accessibilityLabel("Add a recipe")
          .accessibilityIdentifier("addRecipe")
        }
        ToolbarItem(placement: .topBarTrailing) {
          Menu {
            Button {
                if inbox.pending.isEmpty { importPresentation = ImportPresentation(request: nil) }
              else { reviewPendingImport() }
            } label: {
              Label("Import recipe", systemImage: "square.and.arrow.down")
            }.accessibilityIdentifier("importRecipe")
            Button {
                showingSettings = true
            } label: {
              Label("Settings", systemImage: "gearshape")
            }
          } label: {
            Image(systemName: "ellipsis")
          }.accessibilityLabel("Library options")
        }
      }
    } detail: {
      if let recipe = selectedRecipe {
        RecipeDetailView(recipe: recipe) {
          selectedRecipeID = nil
          preferredCompactColumn = .sidebar
        }
        .id(recipe.id)
      } else {
        ContentUnavailableView {
          Label("Your recipe, right here", systemImage: "book.pages")
        } description: {
          Text(
            recipes.isEmpty
              ? "Add a recipe to start your personal recipe book."
              : "Choose a recipe from your library to see its ingredients, method, and cooking notes."
          )
        } actions: {
          if recipes.isEmpty {
            Button("Add a recipe") { showingEditor = true }
              .buttonStyle(.borderedProminent)
          }
        }
        .sazliScreen()
        .navigationTitle("Your recipe book")
        .navigationBarTitleDisplayMode(.inline)
      }
    }
    .navigationSplitViewStyle(.balanced)
    .sheet(isPresented: $showingEditor) { RecipeEditorView() }
    .sheet(isPresented: $showingSettings) { SettingsView() }
    .sheet(item: $importPresentation) { presentation in
      ImportRecipeView(request: presentation.request) { id in
        if let request = presentation.request { acknowledgeImport(request.id) }
        selectedRecipeID = id
        preferredCompactColumn = .detail
      } onDiscard: {
        if let request = presentation.request { acknowledgeImport(request.id) }
      }
    }
    .alert("Recipe import", isPresented: Binding(
      get: { importError != nil }, set: { if !$0 { importError = nil } }
    )) { Button("OK") { importError = nil } } message: { Text(importError ?? "") }
    .task { refreshImportInbox() }
    .onChange(of: scenePhase) { _, phase in
      if phase == .active { refreshImportInbox() }
    }
    .onChange(of: inbox.pending.first?.id, initial: true) { _, id in
      if id != nil { reviewPendingImport() }
    }
    .onChange(of: recipes.map(\.id)) { _, ids in
      if let selectedRecipeID, !ids.contains(selectedRecipeID) {
        self.selectedRecipeID = nil
        preferredCompactColumn = .sidebar
      }
    }
  }

  private func libraryContent(width: CGFloat) -> some View {
    return VStack(alignment: .leading, spacing: 28) {
      if !inbox.pending.isEmpty {
        Button(action: reviewPendingImport) {
          Label("Review shared recipe (\(inbox.pending.count))", systemImage: "tray.and.arrow.down")
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(SazliTheme.surface, in: RoundedRectangle(cornerRadius: 18))
        }.buttonStyle(.plain).foregroundStyle(SazliTheme.terracotta)
      }
      if let message = inbox.errorMessage {
        VStack(alignment: .leading, spacing: 8) {
          Text(message).font(.footnote).foregroundStyle(.secondary)
          Button("Retry imports") { refreshImportInbox() }
        }
      }
      filters
      if filteredRecipes.isEmpty {
        RecipeEmptyState(isSearching: !recipes.isEmpty || !search.isEmpty || filter != .all) {
          showingEditor = true
        }
        .padding(.top, 20)
      } else {
        VStack(alignment: .leading, spacing: 16) {
          Text("\(filteredRecipes.count) \(filteredRecipes.count == 1 ? "recipe" : "recipes")")
            .font(.subheadline).foregroundStyle(.secondary)
          LazyVStack(spacing: 14) {
            ForEach(filteredRecipes) { recipe in
              Button {
                selectedRecipeID = recipe.id
                preferredCompactColumn = .detail
              } label: {
                RecipeCard(recipe: recipe, compact: width < 380)
                  .overlay {
                    if selectedRecipeID == recipe.id {
                      RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(SazliTheme.terracotta, lineWidth: 2)
                    }
                  }
              }
              .buttonStyle(.plain)
              .accessibilityAddTraits(selectedRecipeID == recipe.id ? .isSelected : [])
            }
          }
        }
      }
    }
  }

  private func refreshImportInbox() {
    inbox.reload()
    if !inbox.pending.isEmpty { reviewPendingImport() }
  }

  private func reviewPendingImport() {
    guard !showingEditor, !showingSettings, importPresentation == nil,
          let request = inbox.pending.first else { return }
    if recipes.contains(where: { $0.id == request.id }) {
      // The recipe was saved before the app stopped, but its inbox file remains.
      acknowledgeImport(request.id)
      selectedRecipeID = request.id
      preferredCompactColumn = .detail
      return
    }
    importPresentation = ImportPresentation(request: request)
  }

  private func acknowledgeImport(_ id: UUID) {
    do { try inbox.remove(id) }
    catch { importError = "The import could not be removed from the inbox. It has been kept for retry. \(error.localizedDescription)" }
  }

  private var libraryBrand: some View {
    Image("BrandLogo")
      .resizable()
      .scaledToFit()
      .frame(width: 36, height: 36)
      .clipShape(RoundedRectangle(cornerRadius: 10))
      .accessibilityLabel("Sazli")
      .accessibilityAddTraits(.isHeader)
      .accessibilityIdentifier("libraryBrand")
  }

  private var filters: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 10) {
        ForEach(LibraryFilter.allCases) { item in
          Button {
            filter = item
          } label: {
            Text(item.title)
              .font(.subheadline.weight(.medium))
              .padding(.horizontal, 18).padding(.vertical, 12)
              .background(
                filter == item ? SazliTheme.terracotta : SazliTheme.surface, in: Capsule()
              )
              .foregroundStyle(filter == item ? Color.white : Color.primary)
          }
          .buttonStyle(.plain)
          .accessibilityAddTraits(filter == item ? .isSelected : [])
        }
      }
    }
  }
}

private struct ImportPresentation: Identifiable {
  let id = UUID()
  let request: PendingRecipeImport?
}

private enum LibraryFilter: String, CaseIterable, Identifiable {
  case all, favorites, breakfast, lunch, dinner, dessert
  var id: Self { self }
  var title: String {
    switch self {
    case .all: "All"
    case .favorites: "Favorites"
    case .breakfast: "Breakfast"
    case .lunch: "Lunch"
    case .dinner: "Dinner"
    case .dessert: "Dessert"
    }
  }
  func includes(_ recipe: Recipe) -> Bool {
    switch self {
    case .all: true
    case .favorites: recipe.isFavorite
    default: recipe.category == rawValue
    }
  }
}
