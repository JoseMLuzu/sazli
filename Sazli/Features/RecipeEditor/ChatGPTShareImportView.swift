import SwiftUI

struct ChatGPTShareImportView: View {
    @Environment(\.dismiss) private var dismiss
    let url: URL
    let importIdentifier: UUID?
    let onSave: (Recipe) -> Void
    @State private var candidates: [SharedRecipeCandidate] = []
    @State private var selected: SharedRecipeCandidate?
    @State private var errorMessage: String?
    @State private var finishedReading = false
    @State private var readConversation = false
    @State private var savedRecipe: Recipe?
    @State private var attempt = UUID()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Label("From ChatGPT to your recipe book", systemImage: "text.book.closed")
                        .font(.title3.weight(.semibold)).foregroundStyle(SazliTheme.terracotta)
                    if !finishedReading {
                        ProgressView("Reading the public conversation…")
                        Text("Sazli reads this shared page on your iPhone. Your ChatGPT account is not required.")
                            .font(.subheadline).foregroundStyle(.secondary)
                        ChatGPTShareWebView(url: url, onRead: receive)
                            .id(attempt)
                            .frame(height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    } else if let errorMessage {
                        ContentUnavailableView {
                            Label(readConversation ? "No complete recipe found" : "Couldn't read this conversation",
                                  systemImage: "link.badge.plus")
                        } description: { Text(errorMessage) } actions: {
                            Button("Try again") {
                                self.errorMessage = nil
                                attempt = UUID()
                                finishedReading = false
                                readConversation = false
                            }.buttonStyle(.bordered)
                            Button("Paste recipe text instead") { dismiss() }
                        }
                    } else {
                        Text(candidates.count == 1 ? "Your recipe is ready to review." : "Choose a recipe to review. Follow-up advice has not been mixed into its cooking steps.")
                            .foregroundStyle(.secondary)
                        ForEach(candidates) { candidate in
                            Button { selected = candidate } label: {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(candidate.draft.title).font(.headline).foregroundStyle(.primary)
                                    Text("\(RecipeText.lines(in: candidate.draft.ingredients).count) ingredients · \(RecipeText.lines(in: candidate.draft.instructions).count) steps")
                                        .font(.subheadline).foregroundStyle(.secondary)
                                    Label("Review recipe", systemImage: "arrow.right")
                                        .font(.subheadline.weight(.semibold)).foregroundStyle(SazliTheme.terracotta)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading).padding(20)
                                .background(SazliTheme.surface, in: RoundedRectangle(cornerRadius: 22))
                            }.buttonStyle(.plain)
                        }
                    }
                    Button("Keep the link only") { keepLink() }
                        .buttonStyle(.bordered)
                    Text("Only details present in an explicit recipe are filled in. Photos and later conversation changes are not imported automatically.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                .padding(20).frame(maxWidth: 720).frame(maxWidth: .infinity)
            }
            .sazliScreen()
            .navigationTitle("Import from ChatGPT")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
            .sheet(item: $selected, onDismiss: finishIfSaved) { candidate in
                RecipeEditorView(draft: candidate.draft, importIdentifier: importIdentifier) { recipe in
                    savedRecipe = recipe
                }
            }
        }
    }

    private func receive(_ result: Result<[String], Error>) {
        finishedReading = true
        switch result {
        case .success(let messages):
            readConversation = true
            candidates = ChatGPTRecipeExtractor.recipes(in: messages, sourceURL: url)
            if candidates.isEmpty {
                errorMessage = "No complete recipe with explicit ingredients and instructions was found. Import the recipe text, or keep this link to complete it later."
            } else if candidates.count == 1 { selected = candidates[0] }
        case .failure(let error): errorMessage = error.localizedDescription
        }
    }

    private func keepLink() {
        guard let draft = try? RecipeImportParser.parse(url.absoluteString) else { return }
        selected = SharedRecipeCandidate(draft: draft)
    }

    private func finishIfSaved() {
        guard let savedRecipe else { return }
        onSave(savedRecipe)
        dismiss()
    }
}
