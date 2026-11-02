import SwiftData
import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable {
  case system, light, dark
  var id: Self { self }
  var title: String { rawValue.capitalized }
  var colorScheme: ColorScheme? {
    switch self {
    case .system: nil
    case .light: .light
    case .dark: .dark
    }
  }
}

struct SettingsView: View {
  @Environment(\.dismiss) private var dismiss
  @AppStorage("appearance") private var appearance = AppAppearance.system
  #if DEBUG
    @Environment(\.modelContext) private var context
    @State private var sampleMessage: String?
  #endif

  var body: some View {
    NavigationStack {
      Form {
        Section("Make yourself at home") {
          Picker("Appearance", selection: $appearance) {
            ForEach(AppAppearance.allCases) { Text($0.title).tag($0) }
          }
        }
        Section("Your personal recipe book") {
          Label("Saved on this iPhone", systemImage: "iphone")
          Text(
            "Your recipes and photos are stored locally. No account or internet connection is needed to use your recipe book. Opening original links requires a connection."
          )
          .foregroundStyle(.secondary)
          Text("Cloud sync is not enabled. Deleting the app removes its local recipe book.")
            .font(.footnote).foregroundStyle(.secondary)
        }
        Section("Bring your recipes") {
          NavigationLink {
            RecipeImportHelpView()
          } label: {
            Label("Import from other apps", systemImage: "square.and.arrow.down")
          }
        }
        Section {
          LabeledContent(
            "Sazli",
            value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
        }
        #if DEBUG
          Section {
            Button(action: importSamples) {
              Label("Add sample recipes", systemImage: "photo.stack")
            }
            .accessibilityIdentifier("importSampleRecipes")
          } header: {
            Text("Try the recipe book")
          } footer: {
            Text(
              "Adds four example recipes with illustrative AI-generated photos. Existing recipes and edits are kept."
            )
          }
        #endif
      }
      .sazliScreen()
      .navigationTitle("Settings").navigationBarTitleDisplayMode(.inline)
      .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
      #if DEBUG
        .alert(
          "Sample recipes",
          isPresented: Binding(
            get: { sampleMessage != nil }, set: { if !$0 { sampleMessage = nil } }
          )
        ) {
          Button("OK") { sampleMessage = nil }
        } message: {
          Text(sampleMessage ?? "")
        }
      #endif
    }
  }

  #if DEBUG
    private func importSamples() {
      do {
        let count = try SampleRecipeImporter.importRecipes(in: context)
        sampleMessage =
          count == 0
          ? "These sample recipes are already in your library."
          : "Added \(count) sample recipes with photos to your library."
      } catch { sampleMessage = error.localizedDescription }
    }
  #endif
}
