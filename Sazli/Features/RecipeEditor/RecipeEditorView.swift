import SwiftUI
import SwiftData
import PhotosUI

struct RecipeEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    private let recipe: Recipe?
    private let initialDraft: RecipeDraft
    private let importIdentifier: UUID?
    private let recoveredImportedSections: Bool
    private let onSave: ((Recipe) -> Void)?
    @State private var draft: RecipeDraft
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var loadingPhoto = false
    @State private var importingPhoto = false
    @State private var photoRequest: PhotoRequest?
    @State private var completedPhotoRequest: UUID?
    @State private var sourceRequest: SourceRequest?
    @State private var chatGPTRequest: SourceRequest?
    @State private var importingSourceDetails = false
    @State private var sourceImportMessage: String?
    @State private var importPhotoMessage: String?
    @State private var importNotice: String?
    @State private var showingImport = false
    @State private var confirmingDiscard = false
    @State private var errorMessage: String?
    @FocusState private var focused: Bool

    private struct SourceRequest: Identifiable {
        let id = UUID()
        let url: URL
    }

    private struct PhotoRequest {
        let id = UUID()
        let urls: [URL]
        let source: RecipeRemotePhoto.Source
    }

    init(recipe: Recipe? = nil, draft importedDraft: RecipeDraft? = nil, importIdentifier: UUID? = nil,
         importPhotoURLs: [URL]? = nil, importPhotoSource: RecipeRemotePhoto.Source = .chatGPT,
         importNotice: String? = nil, onSave: ((Recipe) -> Void)? = nil) {
        self.recipe = recipe
        self.importIdentifier = importIdentifier
        _photoRequest = State(initialValue: importPhotoURLs.map { PhotoRequest(urls: $0, source: importPhotoSource) })
        _importNotice = State(initialValue: importNotice)
        self.onSave = onSave
        var draft = recipe.map(RecipeDraft.init) ?? importedDraft ?? RecipeDraft()
        recoveredImportedSections = draft.recoverTikTokSectionsIfNeeded()
        initialDraft = draft
        _draft = State(initialValue: draft)
    }

    var body: some View {
        let photoPickerTitle = draft.imageData == nil ? "Choose a photo" : "Change photo"
        NavigationStack {
            Form {
                Section {
                    TextField("Recipe name", text: $draft.title, axis: .vertical)
                        .font(.title3.weight(.semibold)).focused($focused)
                        .accessibilityIdentifier("recipeTitle")
                    TextField("A few words about this recipe (optional)", text: $draft.description, axis: .vertical)
                        .lineLimit(3...6).focused($focused)
                    if recoveredImportedSections {
                        Text("The imported text has been organized into ingredients and steps. Review it before saving.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                    if let importNotice {
                        Text(importNotice).font(.footnote).foregroundStyle(.secondary)
                    }
                } header: { Text("The essentials") } footer: {
                    Text("A name is all you need. Save a link now and fill in the details whenever you're ready.")
                }

                Section("Photo") {
                    if let data = draft.imageData, let image = UIImage(data: data) {
                        Image(uiImage: image).resizable().scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        Button("Remove photo", role: .destructive) {
                            draft.imageData = nil
                            selectedPhoto = nil
                        }
                    }
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label(photoPickerTitle, systemImage: "photo")
                    }
                    .disabled(loadingPhoto)
                    if loadingPhoto { ProgressView("Preparing photo…") }
                    if importingPhoto {
                        Button("Continue without imported photo") {
                            photoRequest = nil
                            importingPhoto = false
                            loadingPhoto = false
                            importPhotoMessage = "You can add a photo from Photos."
                        }
                    }
                    if let importPhotoMessage {
                        Text(importPhotoMessage).font(.footnote).foregroundStyle(.secondary)
                    }
                }

                Section("Details") {
                    Picker("Category", selection: $draft.category) {
                        ForEach(RecipeCategory.allCases) { Text($0.title).tag($0) }
                    }
                    LabeledContent("Time (minutes)") {
                        TextField("Optional", text: $draft.preparationTime)
                            .keyboardType(.numberPad).multilineTextAlignment(.trailing)
                            .focused($focused).accessibilityLabel("Preparation time in minutes")
                    }
                    LabeledContent("Servings") {
                        TextField("1", text: $draft.servings)
                            .keyboardType(.numberPad).multilineTextAlignment(.trailing)
                            .focused($focused).accessibilityLabel("Servings")
                    }
                }

                Section {
                    Button { focused = false; showingImport = true } label: {
                        Label("Paste recipe text", systemImage: "doc.on.clipboard")
                    }
                    multiline("Ingredients, one per line", text: $draft.ingredients)
                } header: { Text("Ingredients") } footer: { Text("Use a new line for each ingredient, including its quantity.") }

                Section {
                    multiline("Preparation steps, one per line", text: $draft.instructions)
                } header: { Text("Method") } footer: { Text("Each nonempty line becomes a step in cooking mode.") }

                Section {
                    TextField("https://…", text: $draft.sourceURL)
                        .keyboardType(.URL).textContentType(.URL)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                        .focused($focused).accessibilityLabel("Original recipe link")
                        .accessibilityIdentifier("recipeSourceURL")
                    if let url = SourceLink.videoRecipeURL(from: draft.sourceURL) {
                        Button {
                            focused = false
                            sourceRequest = SourceRequest(url: url)
                        } label: {
                            Label("Import recipe details", systemImage: "square.and.arrow.down")
                        }
                        .disabled(importingSourceDetails || loadingPhoto)
                        .accessibilityIdentifier("importSourceRecipe")
                    } else if let url = SourceLink.chatGPTShareURL(from: draft.sourceURL) {
                        Button {
                            focused = false
                            chatGPTRequest = SourceRequest(url: url)
                        } label: {
                            Label("Import recipe details", systemImage: "square.and.arrow.down")
                        }
                        .disabled(loadingPhoto || importingSourceDetails)
                        .accessibilityIdentifier("importSourceRecipe")
                    }
                    if importingSourceDetails { ProgressView("Reading the public description…") }
                    if let sourceImportMessage {
                        Text(sourceImportMessage).font(.footnote).foregroundStyle(.secondary)
                    }
                    Picker("Platform", selection: $draft.sourcePlatform) {
                        ForEach(SourcePlatform.allCases) { Text($0.title).tag($0) }
                    }
                } header: { Text("Original source") } footer: {
                    Text("For a public ChatGPT share or a supported TikTok/YouTube/Instagram video, tap Import recipe details to fill empty fields. Review the recipe before saving. Your existing details and original link are kept.")
                }
            }
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
            .sazliScreen()
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(recipe == nil ? "New recipe" : "Edit recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if draft != initialDraft { confirmingDiscard = true }
                        else { dismiss() }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).fontWeight(.semibold).disabled(loadingPhoto || importingSourceDetails)
                        .accessibilityIdentifier("saveRecipe")
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focused = false }
                }
            }
            .interactiveDismissDisabled(draft != initialDraft || loadingPhoto || importingSourceDetails)
            .task(id: photoRequest?.id) { await loadImportedPhoto() }
            .task(id: sourceRequest?.id) { await loadSourceDetails() }
            .confirmationDialog("Discard your changes?", isPresented: $confirmingDiscard, titleVisibility: .visible) {
                Button("Discard changes", role: .destructive) { dismiss() }
                Button("Keep editing", role: .cancel) {}
            }
            .alert("Couldn't save changes", isPresented: hasError) {
                Button("OK") { errorMessage = nil }
            } message: { Text(errorMessage ?? "Please try again.") }
            .sheet(isPresented: $showingImport) {
                PasteRecipeTextView { text, destination in
                    switch destination {
                    case .ingredients: draft.ingredients = append(text, to: draft.ingredients)
                    case .instructions: draft.instructions = append(text, to: draft.instructions)
                    case .description: draft.description = append(text, to: draft.description)
                    }
                }
            }
            .sheet(item: $chatGPTRequest) { request in
                ChatGPTShareImportView(url: request.url, importIdentifier: nil, onChoose: { candidate in
                    guard let current = SourceLink.chatGPTShareURL(from: draft.sourceURL),
                          SourceLink.sameChatGPTShare(current, request.url) else { return }
                    applySourceDetails(candidate.draft, photoURLs: candidate.photoURLs, photoSource: .chatGPT)
                })
            }
            .onChange(of: draft.sourceURL) { _, value in
                draft.sourcePlatform = SourceLink.platform(for: value)
                sourceRequest = nil
                chatGPTRequest = nil
                importingSourceDetails = false
                sourceImportMessage = nil
                importNotice = nil
                if let request = photoRequest, completedPhotoRequest != request.id {
                    photoRequest = nil
                    importingPhoto = false
                    loadingPhoto = false
                }
            }
            .task(id: selectedPhoto) { await loadPhoto() }
        }
    }

    private func loadImportedPhoto() async {
        guard let request = photoRequest, completedPhotoRequest != request.id else { return }
        guard !request.urls.isEmpty else {
            completedPhotoRequest = request.id
            importPhotoMessage = "No accessible recipe photo was found. You can choose one from Photos."
            return
        }
        loadingPhoto = true
        importingPhoto = true
        defer {
            if photoRequest?.id == request.id {
                loadingPhoto = false
                importingPhoto = false
            }
        }
        let data = await RecipeRemotePhoto.load(from: request.urls, source: request.source)
        guard !Task.isCancelled, photoRequest?.id == request.id else { return }
        completedPhotoRequest = request.id
        if let data {
            if draft.imageData == nil { draft.imageData = data }
        }
        else { importPhotoMessage = "The photo couldn't be imported. Your recipe is ready; you can choose a photo from Photos." }
    }

    private func loadSourceDetails() async {
        guard let request = sourceRequest else { return }
        importingSourceDetails = true
        sourceImportMessage = nil
        defer { if sourceRequest?.id == request.id { importingSourceDetails = false } }
        do {
            let imported = try await VideoRecipeReader.read(from: request.url)
            guard !Task.isCancelled, sourceRequest?.id == request.id,
                  SourceLink.videoRecipeURL(from: draft.sourceURL) == request.url else { return }
            applySourceDetails(imported.draft, photoURLs: imported.photoURLs, photoSource: imported.photoSource,
                               notice: imported.notice)
        } catch {
            guard !Task.isCancelled, sourceRequest?.id == request.id else { return }
            sourceImportMessage = error.localizedDescription
        }
    }

    private func applySourceDetails(_ imported: RecipeDraft, photoURLs: [URL],
                                    photoSource: RecipeRemotePhoto.Source, notice: String? = nil) {
        importNotice = nil
        draft.recoverTikTokSectionsIfNeeded()
        draft.fillEmptyDetails(from: imported,
                               useDefaultServings: recipe == nil && draft.servings == initialDraft.servings)
        let ingredients = RecipeText.ingredientLines(in: draft.ingredients).count
        let steps = RecipeText.lines(in: draft.instructions).count
        sourceImportMessage = notice ?? "\(ingredients) ingredients · \(steps) steps. Empty fields were filled; review the recipe before saving."
        if draft.imageData == nil, selectedPhoto == nil, !photoURLs.isEmpty {
            importPhotoMessage = nil
            loadingPhoto = true
            photoRequest = PhotoRequest(urls: photoURLs, source: photoSource)
        }
    }

    private var hasError: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    private func multiline(_ prompt: String, text: Binding<String>) -> some View {
        TextEditor(text: text)
            .font(.body)
            .frame(minHeight: 150)
            .focused($focused)
            .accessibilityLabel(prompt)
            .overlay(alignment: .topLeading) {
                if text.wrappedValue.isEmpty {
                    Text(prompt).foregroundStyle(.tertiary)
                        .padding(.top, 8).padding(.leading, 5)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
    }

    private func append(_ text: String, to existing: String) -> String {
        existing.isEmpty ? text : existing + "\n" + text
    }

    private func save() {
        focused = false
        do {
            let saved = try RecipeStore.save(draft, editing: recipe, in: context, importIdentifier: importIdentifier)
            onSave?(saved)
            dismiss()
        } catch { errorMessage = error.localizedDescription }
    }

    @MainActor private func loadPhoto() async {
        guard let selectedPhoto else { return }
        photoRequest = nil
        importingPhoto = false
        loadingPhoto = true
        defer { loadingPhoto = false }
        do {
            guard let data = try await selectedPhoto.loadTransferable(type: Data.self) else {
                throw RecipePhoto.PhotoError.unreadable
            }
            let prepared = try await Task.detached(priority: .userInitiated) {
                try RecipePhoto.prepare(data)
            }.value
            try Task.checkCancellation()
            draft.imageData = prepared
        } catch is CancellationError {
            // A dismissed editor must not be updated by a completed photo request.
        } catch { errorMessage = error.localizedDescription }
    }
}
