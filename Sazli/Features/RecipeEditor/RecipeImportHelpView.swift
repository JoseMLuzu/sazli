import SwiftUI

struct RecipeImportHelpView: View {
    var body: some View {
        Form {
            Section("Copy and paste") {
                Text("Copy the recipe response from ChatGPT, or copy a video or webpage link. In Sazli, choose Import recipe, paste, and tap Review recipe.")
                Text("For ChatGPT, share a public conversation link or copy the recipe text. Sazli can read supported public share pages directly on this iPhone and offers complete recipes for review. Private or unreadable links can still be kept as references.")
                    .foregroundStyle(.secondary)
            }
            Section("Share directly to Sazli") {
                step(1, "In ChatGPT or another app, open the system Share sheet and choose Sazli. Look under More if it is not visible yet.")
                step(2, "Tap Add to imports, then Done. The original shared link or text stays on this iPhone.")
                step(3, "Open Sazli. Review the shared recipe, complete any missing details, and tap Save.")
                Text("No shortcut setup is needed. Only the text or link supplied by the source app is received; private accounts and chats are not connected.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section("Optional shortcut") {
                step(1, "Open Apple's Shortcuts app and create a shortcut named Send to Sazli.")
                step(2, "In the shortcut's Details, enable Show in Share Sheet. Accept Text and URLs.")
                step(3, "Add Sazli's Import recipe action. Set Recipe text or link to Shortcut Input.")
                step(4, "Save the shortcut. In another app, open the iOS share sheet and choose Send to Sazli. Sazli opens with the shared content ready to review.")
                if let url = URL(string: "shortcuts://") {
                    Link("Open Shortcuts", destination: url)
                }
                Text("If an app only offers its own sharing menu, choose its system Share option or Copy Link, then paste in Sazli.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section("What is imported") {
                Label("Recipe text: explicit ingredients and steps", systemImage: "text.alignleft")
                Label("Public ChatGPT links: complete recipe sections", systemImage: "text.book.closed")
                Label("TikTok videos: public description and available cover", systemImage: "text.below.photo")
                Label("YouTube videos: public description and available thumbnail", systemImage: "play.rectangle")
                Label("Other links: original URL and detected platform", systemImage: "link")
                Text("Your private conversations and accounts are not connected. Reading a public ChatGPT page requires internet access and uses an isolated browser session. Video transcription, image recognition, and general webpage extraction are not included. Nothing is uploaded by Sazli.")
                    .foregroundStyle(.secondary)
            }
        }
        .sazliScreen()
        .navigationTitle("Import from other apps")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func step(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)").font(.subheadline.bold()).foregroundStyle(SazliTheme.terracotta)
                .frame(width: 24)
            Text(text)
        }.accessibilityElement(children: .combine)
    }
}
