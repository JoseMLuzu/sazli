import SwiftUI

struct IngredientRow: View {
  let text: String
  var isPrepared = false
  var onToggle: (() -> Void)?

  var body: some View {
    if let onToggle {
      Button(action: onToggle) { content }
        .buttonStyle(.plain)
        .accessibilityLabel(text)
        .accessibilityValue(isPrepared ? "Prepared" : "Not prepared")
        .accessibilityHint(
          isPrepared ? "Double-tap to mark as not prepared." : "Double-tap to mark as prepared."
        )
        .accessibilityAddTraits(isPrepared ? .isSelected : [])
    } else {
      content.accessibilityElement(children: .combine)
    }
  }

  private var content: some View {
    HStack(alignment: .top, spacing: 12) {
      Group {
        if onToggle != nil {
          Image(systemName: isPrepared ? "checkmark.circle.fill" : "circle")
            .font(.title3.weight(.medium))
        } else {
          Circle().fill(SazliTheme.olive.opacity(0.13))
            .frame(width: 22, height: 22)
            .overlay { Circle().fill(SazliTheme.olive).frame(width: 6, height: 6) }
        }
      }
      .foregroundStyle(SazliTheme.olive)
      .frame(width: 24, height: 26)
      .accessibilityHidden(true)
      Text(text)
        .font(.body.weight(.medium))
        .lineSpacing(3)
        .strikethrough(isPrepared)
        .foregroundStyle(isPrepared ? .secondary : .primary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(.vertical, 10)
    .frame(minHeight: 44, alignment: .leading)
    .contentShape(Rectangle())
  }
}
