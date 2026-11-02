import SwiftUI
import SwiftData

@main
struct SazliApp: App {
    @AppStorage("appearance") private var appearance = AppAppearance.system
    private let container: ModelContainer?
    private let startupError: String?
    #if DEBUG
    @State private var sampleImportError: String?
    #endif

    init() {
        do {
            container = try RecipeStore.container()
            container?.mainContext.autosaveEnabled = false
            startupError = nil
        } catch {
            container = nil
            startupError = error.localizedDescription
        }
    }

    var body: some Scene {
        WindowGroup {
            if let container {
                LibraryView()
                    .modelContainer(container)
                    .tint(SazliTheme.terracotta)
                    .preferredColorScheme(appearance.colorScheme)
                    #if DEBUG
                    .task { @MainActor in
                        guard ProcessInfo.processInfo.arguments.contains(SampleRecipeImporter.launchArgument) else { return }
                        do {
                            let added = try SampleRecipeImporter.importRecipes(in: container.mainContext)
                            let recipes = try container.mainContext.fetch(FetchDescriptor<Recipe>())
                            let photos = recipes.filter { $0.imageData != nil }.count
                            print("Sazli sample import complete: \(added) added; \(recipes.count) recipes; \(photos) with photos.")
                        } catch {
                            sampleImportError = error.localizedDescription
                            print("Sazli sample import failed: \(error.localizedDescription)")
                        }
                    }
                    .alert("Couldn't add sample recipes", isPresented: Binding(
                        get: { sampleImportError != nil }, set: { if !$0 { sampleImportError = nil } }
                    )) { Button("OK") { sampleImportError = nil } } message: { Text(sampleImportError ?? "") }
                    #endif
            } else {
                ContentUnavailableView {
                    Label("Your recipe book couldn't open", systemImage: "externaldrive.badge.exclamationmark")
                } description: {
                    Text("Please close Sazli and try again. Your saved data has not been removed.")
                    Text(startupError ?? "Storage is unavailable.").font(.caption)
                }
                .background(SazliTheme.background)
            }
        }
    }
}
