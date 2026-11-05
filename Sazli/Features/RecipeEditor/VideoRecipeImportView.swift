import SwiftUI

struct VideoRecipeImportView: View {
    @Environment(\.dismiss) private var dismiss
    let url: URL
    let importIdentifier: UUID?
    let onSave: (Recipe) -> Void
    @State private var selected: SharedRecipeCandidate?
    @State private var savedRecipe: Recipe?
    @State private var errorMessage: String?
    @State private var reading = true
    @State private var useLinkOnly = false
    @State private var attempt = UUID()
    @State private var imported: VideoRecipeImport?

    private var platform: SourcePlatform { VideoRecipeReader.platform(for: url) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Label("From \(platform.title) to your recipe book", systemImage: "text.book.closed")
                        .font(.title3.weight(.semibold)).foregroundStyle(SazliTheme.terracotta)
                    if reading {
                        ProgressView("Reading the public video description…")
                    } else if let errorMessage {
                        ContentUnavailableView {
                            Label("Couldn't read this video", systemImage: "link.badge.plus")
                        } description: { Text(errorMessage) } actions: {
                            Button("Try again") { useLinkOnly = false; attempt = UUID() }
                            Button("Paste the description instead") { dismiss() }
                        }
                    } else if let imported {
                        if let notice = imported.notice { Text(notice).foregroundStyle(.secondary) }
                        Text(imported.draft.ingredients.isEmpty || imported.draft.instructions.isEmpty
                             ? "The description doesn't include a complete recipe. You can review the available text and fill in the rest."
                             : "The recipe in the description is ready to review.")
                        Button("Review recipe") {
                            selected = SharedRecipeCandidate(draft: imported.draft, photoURLs: imported.photoURLs)
                        }.buttonStyle(.borderedProminent)
                    }
                    Button("Keep the link only") { keepLink() }.buttonStyle(.bordered)
                    Text("Sazli reads the public description and tries to import the video's cover. It doesn't transcribe audio or read instructions shown only inside the video. Review the recipe before saving.")
                        .font(.footnote).foregroundStyle(.secondary)
                }.padding(20).frame(maxWidth: 720).frame(maxWidth: .infinity)
            }
            .sazliScreen()
            .navigationTitle("Import from \(platform.title)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
            .task(id: useLinkOnly ? nil : attempt) {
                guard !useLinkOnly else { return }
                reading = true
                errorMessage = nil
                do {
                    let result = try await VideoRecipeReader.read(from: url)
                    guard !Task.isCancelled else { return }
                    imported = result
                    reading = false
                    selected = SharedRecipeCandidate(draft: result.draft, photoURLs: result.photoURLs)
                } catch {
                    guard !Task.isCancelled else { return }
                    reading = false
                    errorMessage = error.localizedDescription
                }
            }
            .sheet(item: $selected, onDismiss: finishIfSaved) { candidate in
                RecipeEditorView(draft: candidate.draft, importIdentifier: importIdentifier,
                                 importPhotoURLs: useLinkOnly ? nil : candidate.photoURLs,
                                 importPhotoSource: imported?.photoSource ?? .tikTok,
                                 importNotice: useLinkOnly ? nil : imported?.notice) { savedRecipe = $0 }
            }
        }
    }

    private func keepLink() {
        guard let draft = try? RecipeImportParser.parse(url.absoluteString) else { return }
        useLinkOnly = true
        reading = false
        selected = SharedRecipeCandidate(draft: draft)
    }

    private func finishIfSaved() {
        guard let savedRecipe else { return }
        onSave(savedRecipe)
        dismiss()
    }
}
