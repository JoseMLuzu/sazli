import SwiftUI

struct ImportRecipeView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var text: String
    @State private var platform: SourcePlatform = .manual
    @State private var review: ImportReview?
    @State private var errorMessage: String?
    @State private var savedID: UUID?
    @State private var confirmingDiscard = false
    @State private var confirmingClose = false
    @FocusState private var focused: Bool
    private let request: PendingRecipeImport?
    private let onSaved: (UUID) -> Void
    private let onDiscard: () -> Void

    init(request: PendingRecipeImport? = nil, onSaved: @escaping (UUID) -> Void, onDiscard: @escaping () -> Void = {}) {
        self.request = request
        self.onSaved = onSaved
        self.onDiscard = onDiscard
        _text = State(initialValue: request?.text ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label("From inspiration to your recipe book", systemImage: "square.and.arrow.down")
                        .font(.headline).foregroundStyle(SazliTheme.terracotta)
                    Text("Copy a recipe from ChatGPT, or a link from YouTube, Facebook, TikTok, or the web. Paste it here, then review the details.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Section {
                    PasteButton(payloadType: String.self) { values in
                        text = values.joined(separator: "\n\n")
                    }
                    .labelStyle(.titleAndIcon)
                    TextEditor(text: $text)
                        .focused($focused)
                        .frame(minHeight: 200)
                        .accessibilityLabel("Recipe text or link")
                        .accessibilityIdentifier("recipeImportText")
                        .textInputAutocapitalization(.never)
                    if !text.isEmpty {
                        Button("Clear text", role: .destructive) { text = "" }
                    }
                } header: { Text("Text or original link") } footer: {
                    Text("Headings such as Ingredients / Ingredientes and Instructions / Preparación help organize the recipe. Unrecognized text is kept in the description.")
                }
                Section {
                    Picker("Platform for pasted text", selection: $platform) {
                        ForEach(SourcePlatform.allCases) { Text($0.title).tag($0) }
                    }
                } footer: {
                    Text("Public ChatGPT shares and supported TikTok descriptions can be read on this iPhone. Other links remain references. Video transcription is not included.")
                }
                Section {
                    PrimaryButton(title: "Review recipe", symbol: "arrow.right") { prepareReview() }
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityIdentifier("reviewImportedRecipe")
                }.listRowBackground(Color.clear)
                Section {
                    NavigationLink { RecipeImportHelpView() } label: {
                        Label("Share directly with Shortcuts", systemImage: "square.and.arrow.up")
                    }
                }
                if request != nil {
                    Section {
                        Button("Discard pending import", role: .destructive) { confirmingDiscard = true }
                    } footer: { Text("Closing this screen keeps the original shared text in your inbox until you save or discard it.") }
                }
            }
            .frame(maxWidth: 720).frame(maxWidth: .infinity)
            .sazliScreen()
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Import recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        if request == nil && !text.isEmpty { confirmingClose = true }
                        else { dismiss() }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Review", action: prepareReview)
                        .fontWeight(.semibold)
                        .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focused = false }
                }
            }
            .interactiveDismissDisabled(request == nil && !text.isEmpty)
            .alert("Couldn't import recipe", isPresented: Binding(
                get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
            )) { Button("OK") { errorMessage = nil } } message: { Text(errorMessage ?? "") }
            .confirmationDialog("Discard this shared recipe?", isPresented: $confirmingDiscard, titleVisibility: .visible) {
                Button("Discard import", role: .destructive) { onDiscard(); dismiss() }
                Button("Keep import", role: .cancel) {}
            }
            .confirmationDialog("Close without saving this text?", isPresented: $confirmingClose, titleVisibility: .visible) {
                Button("Discard text", role: .destructive) { dismiss() }
                Button("Keep editing", role: .cancel) {}
            }
            .sheet(item: $review, onDismiss: finishIfSaved) { review in
                switch review.content {
                case .draft(let draft):
                    RecipeEditorView(draft: draft, importIdentifier: request?.id) { recipe in
                        savedID = recipe.id
                    }
                case .chatGPT(let url):
                    ChatGPTShareImportView(url: url, importIdentifier: request?.id) { recipe in
                        savedID = recipe.id
                    }
                case .tikTok(let url):
                    TikTokRecipeImportView(url: url, importIdentifier: request?.id) { recipe in
                        savedID = recipe.id
                    }
                }
            }
            .task {
                if let request, let url = SourceLink.chatGPTShareURL(from: request.text) {
                    review = ImportReview(content: .chatGPT(url))
                } else if let request, let url = SourceLink.tikTokVideoURL(from: request.text) {
                    review = ImportReview(content: .tikTok(url))
                }
            }
        }
    }

    private func prepareReview() {
        focused = false
        if let url = SourceLink.chatGPTShareURL(from: text) {
            review = ImportReview(content: .chatGPT(url))
            return
        }
        if let url = SourceLink.tikTokVideoURL(from: text) {
            review = ImportReview(content: .tikTok(url))
            return
        }
        do {
            var draft = try RecipeImportParser.parse(text)
            if draft.sourceURL.isEmpty { draft.sourcePlatform = platform }
            review = ImportReview(content: .draft(draft))
        } catch { errorMessage = error.localizedDescription }
    }

    private func finishIfSaved() {
        guard let savedID else { return }
        onSaved(savedID)
        dismiss()
    }
}

private struct ImportReview: Identifiable {
    let id = UUID()
    let content: Content
    enum Content {
        case draft(RecipeDraft)
        case chatGPT(URL)
        case tikTok(URL)
    }
}
