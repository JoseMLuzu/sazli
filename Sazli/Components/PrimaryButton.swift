import SwiftUI

struct PrimaryButton: View {
    let title: String
    var symbol = "plus"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 28)
                .padding(.vertical, 10)
        }
        .buttonStyle(.borderedProminent)
        .tint(SazliTheme.terracotta)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
