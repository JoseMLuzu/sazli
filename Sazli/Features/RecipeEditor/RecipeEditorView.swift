import SwiftUI
import SwiftData
import PhotosUI

struct RecipeEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    private let recipe: Recipe?
    private let initialDraft: RecipeDraft
    private let importIdentifier: UUID?
    private let importPhotoURLs: [URL]?
    private let importPhotoSource: RecipeRemotePhoto.Source
    private let onSave: ((Recipe) -> Void)?
    @State private var draft: RecipeDraft
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var loadingPhoto = false
    @State private var importingPhoto = false
    @State private var skipImportedPhoto = false
    @State private var attemptedImportedPhoto = false
    @State private var importPhotoMessage: String?
    @State private var showingImport = false
    @State private var confirmingDiscard = false
    @State private var errorMessage: String?
    @FocusState private var focused: Bool

    init(recipe: Recipe? = nil, draft importedDraft: RecipeDraft? = nil, importIdentifier: UUID? = nil,
         importPhotoURLs: [URL]? = nil, importPhotoSource: RecipeRemotePhoto.Source = .chatGPT, onSave: ((Recipe) -> Void)? = nil) {
        self.recipe = recipe
        self.importIdentifier = importIdentifier
        self.importPhotoURLs = importPhotoURLs
        self.importPhotoSource = importPhotoSource
        self.onSave = onSave
        let draft = recipe.map(RecipeDraft.init) ?? importedDraft ?? RecipeDraft()
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
                            skipImportedPhoto = true
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
                    Picker("Platform", selection: $draft.sourcePlatform) {
                        ForEach(SourcePlatform.allCases) { Text($0.title).tag($0) }
                    }
                } header: { Text("Original source") } footer: {
                    Text("Recognized links set the platform automatically. The original link is kept. Use the library importer to read supported public ChatGPT shares; other links remain references.")
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
                    Button("Save", action: save).fontWeight(.semibold).disabled(loadingPhoto)
                        .accessibilityIdentifier("saveRecipe")
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focused = false }
                }
            }
            .interactiveDismissDisabled(draft != initialDraft || loadingPhoto)
            .task(id: skipImportedPhoto) { await loadImportedPhoto() }
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
            .onChange(of: draft.sourceURL) { _, value in
                draft.sourcePlatform = SourceLink.platform(for: value)
            }
            .task(id: selectedPhoto) { await loadPhoto() }
        }
    }

    private func loadImportedPhoto() async {
        guard let urls = importPhotoURLs, !attemptedImportedPhoto, !skipImportedPhoto else { return }
        attemptedImportedPhoto = true
        guard !urls.isEmpty else {
            importPhotoMessage = "No accessible recipe photo was found. You can choose one from Photos."
            return
        }
        loadingPhoto = true
        importingPhoto = true
        let data = await RecipeRemotePhoto.load(from: urls, source: importPhotoSource)
        guard !Task.isCancelled, !skipImportedPhoto else { return }
        loadingPhoto = false
        importingPhoto = false
        if let data { draft.imageData = data }
        else { importPhotoMessage = "The photo couldn't be imported. Your recipe is ready; you can choose a photo from Photos." }
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
