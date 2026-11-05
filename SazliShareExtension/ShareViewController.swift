import SwiftUI
import UIKit

final class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        let host = UIHostingController(rootView: ShareRecipeView(
            items: extensionContext?.inputItems.compactMap { $0 as? NSExtensionItem } ?? [],
            onCancel: { [weak self] in
                self?.extensionContext?.cancelRequest(withError: CocoaError(.userCancelled))
            }, onDone: { [weak self] in
                self?.extensionContext?.completeRequest(returningItems: nil)
            }))
        addChild(host)
        view.addSubview(host.view)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        host.didMove(toParent: self)
    }
}

private struct ShareRecipeView: View {
    let items: [NSExtensionItem]
    let onCancel: () -> Void
    let onDone: () -> Void
    @State private var content: String?
    @State private var errorMessage: String?
    @State private var saved = false
    @State private var saving = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Image("BrandLogo").resizable().scaledToFit().frame(width: 64, height: 64)
                        .accessibilityHidden(true)
                    if saved {
                        Label("Ready in Sazli", systemImage: "checkmark.circle.fill")
                            .font(.title2.bold()).foregroundStyle(SazliTheme.olive)
                        Text("Open Sazli to review the shared recipe. Your original link or text is waiting in Imports.")
                        Button("Done", action: onDone).buttonStyle(.borderedProminent)
                    } else if let errorMessage {
                        Label("Couldn't receive this recipe", systemImage: "exclamationmark.circle")
                            .font(.title2.bold())
                        Text(errorMessage).foregroundStyle(.secondary)
                    } else if let content {
                        Text("Add to your recipe book").font(.title2.bold())
                        Text(String(content.prefix(500))).font(.body).lineLimit(10)
                            .padding(16).frame(maxWidth: .infinity, alignment: .leading)
                            .background(SazliTheme.surface, in: RoundedRectangle(cornerRadius: 16))
                        Text("Send this to Sazli's import inbox, then open Sazli to review the ingredients and steps before saving.")
                            .foregroundStyle(.secondary)
                        Button("Add to imports", action: send)
                            .buttonStyle(.borderedProminent).disabled(saving)
                            .accessibilityIdentifier("sendSharedRecipe")
                    } else {
                        ProgressView("Receiving recipe…")
                    }
                }.padding(24).frame(maxWidth: 600).frame(maxWidth: .infinity)
            }
            .sazliScreen().tint(SazliTheme.terracotta)
            .navigationTitle("Sazli").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !saved {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel", action: onCancel) }
                }
            }
            .task {
                do {
                    let received = try await ShareContentReader.read(items: items)
                    guard !Task.isCancelled else { return }
                    content = received
                } catch {
                    guard !Task.isCancelled else { return }
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func send() {
        guard let content, !saving else { return }
        saving = true
        do {
            guard let directory = SharedRecipeInbox.groupDirectory else {
                throw SharedRecipeInbox.InboxError.unavailable
            }
            try SharedRecipeInbox(directory: directory).enqueue(content)
            saved = true
        } catch { errorMessage = error.localizedDescription }
        saving = false
    }
}
