import SwiftUI

enum PasteDestination: String, CaseIterable, Identifiable {
    case ingredients, instructions, description
    var id: Self { self }
    var title: String { rawValue.capitalized }
}

struct PasteRecipeTextView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @State private var destination: PasteDestination = .ingredients
    let onImport: (String, PasteDestination) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Add to", selection: $destination) {
                        ForEach(PasteDestination.allCases) { Text($0.title).tag($0) }
                    }
                    PasteButton(payloadType: String.self) { values in
                        text = values.joined(separator: "\n")
                    }
                    TextEditor(text: $text).frame(minHeight: 220)
                        .accessibilityLabel("Recipe text to import")
                } footer: {
                    Text("Paste the text you already have. It will be appended to the selected field exactly as written. You can edit it before saving.")
                }
            }
            .sazliScreen()
            .navigationTitle("Paste recipe text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add text") { onImport(text, destination); dismiss() }
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
