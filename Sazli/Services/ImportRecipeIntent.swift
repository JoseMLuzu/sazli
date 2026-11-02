import AppIntents

/// Included only in the main app: foreground execution uses its private inbox.
struct ImportRecipeIntent: AppIntent {
    static let title: LocalizedStringResource = "Import recipe"
    static let description = IntentDescription("Send recipe text or an original link to Sazli for review. Supported public ChatGPT shares are read on your iPhone; other links remain references. No video transcription or general webpage extraction.")
    static let openAppWhenRun = true

    @Parameter(title: "Recipe text or link", inputConnectionBehavior: .connectToPreviousIntentResult)
    var content: String

    static var parameterSummary: some ParameterSummary {
        Summary("Import \(\.$content) into Sazli")
    }

    @MainActor func perform() async throws -> some IntentResult {
        try RecipeImportInbox.shared.enqueue(content)
        return .result()
    }
}

struct SazliShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: ImportRecipeIntent(), phrases: ["Import a recipe into \(.applicationName)"],
                    shortTitle: "Import recipe", systemImageName: "square.and.arrow.down")
    }
}
