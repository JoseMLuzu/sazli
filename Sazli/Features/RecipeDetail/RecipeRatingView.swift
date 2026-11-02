import SwiftUI
import SwiftData

struct RecipeRatingView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let recipe: Recipe
    @State private var rating: Int
    @State private var notes: String
    @State private var wouldCookAgain: Bool
    @State private var errorMessage: String?
    @State private var confirmingDiscard = false

    init(recipe: Recipe) {
        self.recipe = recipe
        _rating = State(initialValue: recipe.rating)
        _notes = State(initialValue: recipe.notes)
        _wouldCookAgain = State(initialValue: recipe.wouldCookAgain)
    }

    private var hasChanges: Bool {
        rating != recipe.rating || notes != recipe.notes || wouldCookAgain != recipe.wouldCookAgain
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(recipe.title).font(.headline)
                    RatingStars(rating: rating) { rating = $0 }
                    if rating > 0 { Button("Clear rating") { rating = 0 } }
                } header: { Text("How did it turn out?") }
                Section("Notes for next time") {
                    TextField("What worked? What would you change?", text: $notes, axis: .vertical)
                        .lineLimit(5...15)
                    Toggle("I would make this again", isOn: $wouldCookAgain)
                        .tint(SazliTheme.olive)
                }
            }
            .sazliScreen()
            .navigationTitle("Your rating").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { if hasChanges { confirmingDiscard = true } else { dismiss() } }
                }
                ToolbarItem(placement: .confirmationAction) { Button("Save", action: save).fontWeight(.semibold) }
            }
            .interactiveDismissDisabled(hasChanges)
            .confirmationDialog("Discard your changes?", isPresented: $confirmingDiscard, titleVisibility: .visible) {
                Button("Discard changes", role: .destructive) { dismiss() }
                Button("Keep editing", role: .cancel) {}
            }
            .alert("Couldn't save your rating", isPresented: Binding(
                get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } }
            )) { Button("OK") { errorMessage = nil } } message: { Text(errorMessage ?? "Please try again.") }
        }
    }

    private func save() {
        recipe.rating = rating
        recipe.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        recipe.wouldCookAgain = wouldCookAgain
        recipe.updatedAt = Date()
        do { try RecipeStore.commit(in: context); dismiss() }
        catch { errorMessage = error.localizedDescription }
    }
}
