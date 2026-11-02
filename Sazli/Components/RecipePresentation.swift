import SwiftUI

struct RecipeSectionHeading: View {
  let title: String
  let subtitle: String
  let symbol: String
  var tint: Color = SazliTheme.terracotta

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: symbol)
        .font(.system(size: 18, weight: .semibold))
        .foregroundStyle(tint)
        .frame(width: 42, height: 42)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 3) {
        Text(title).font(.title3.weight(.semibold)).accessibilityAddTraits(.isHeader)
        Text(subtitle).font(.caption).foregroundStyle(.secondary)
      }
      .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

struct RecipeInfoTile: View {
  let value: String
  let title: String
  let symbol: String
  var tint: Color = SazliTheme.terracotta

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: symbol)
        .font(.body.weight(.medium)).foregroundStyle(tint)
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: 4) {
        Text(value).font(.subheadline.weight(.semibold))
        Text(title).font(.caption).foregroundStyle(.secondary)
      }
      .fixedSize(horizontal: false, vertical: true)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(14)
    .recipePanel(cornerRadius: 18)
    .accessibilityElement(children: .combine)
  }
}

struct RecipeStepCard: View {
  let number: Int
  let text: String
  var prominent = false

  var body: some View {
    VStack(alignment: .leading, spacing: prominent ? 24 : 14) {
      HStack(spacing: 10) {
        Text(String(format: "%02d", number))
          .font(.system(prominent ? .title2 : .headline, design: .rounded, weight: .bold))
          .monospacedDigit()
          .foregroundStyle(SazliTheme.terracotta)
          .frame(minWidth: prominent ? 56 : 40, minHeight: prominent ? 56 : 40)
          .background(
            SazliTheme.terracotta.opacity(0.11),
            in: RoundedRectangle(cornerRadius: prominent ? 18 : 13))
        Text("STEP \(number)")
          .font(.caption.weight(.semibold)).tracking(1.3)
          .foregroundStyle(SazliTheme.terracotta)
      }
      .accessibilityHidden(true)
      Text(text)
        .font(prominent ? .largeTitle.weight(.medium) : .body)
        .lineSpacing(prominent ? 6 : 4)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(prominent ? 24 : 20)
    .frame(maxWidth: .infinity, minHeight: prominent ? 220 : nil, alignment: .topLeading)
    .recipePanel()
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Step \(number). \(text)")
  }
}

extension View {
  func recipePanel(cornerRadius: CGFloat = 26) -> some View {
    background(SazliTheme.surface, in: RoundedRectangle(cornerRadius: cornerRadius))
      .overlay {
        RoundedRectangle(cornerRadius: cornerRadius)
          .strokeBorder(Color.primary.opacity(0.045), lineWidth: 1)
          .allowsHitTesting(false)
          .accessibilityHidden(true)
      }
  }
}
