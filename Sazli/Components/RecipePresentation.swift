import SwiftUI

struct RecipeSectionHeading: View {
  let title: String
  let subtitle: String
  let symbol: String
  var tint: Color = SazliTheme.terracotta
  var showsIcon = true

  var body: some View {
    HStack(spacing: 12) {
      if showsIcon {
        Image(systemName: symbol)
          .font(.system(size: 18, weight: .semibold))
          .foregroundStyle(tint)
          .frame(width: 42, height: 42)
          .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
          .accessibilityHidden(true)
      }
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
    .accessibilityElement(children: .combine)
  }
}

struct RecipeStepCard: View {
  let number: Int
  let text: String
  var prominent = false

  var body: some View {
    Group {
      if prominent { cookingCard }
      else { readingCard }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Step \(number). \(text)")
  }

  private var readingCard: some View {
    HStack(alignment: .top, spacing: 14) {
      Text("\(number)")
        .font(.subheadline.weight(.semibold)).monospacedDigit()
        .foregroundStyle(SazliTheme.terracotta)
        .frame(minWidth: 30, minHeight: 30)
        .background(SazliTheme.terracotta.opacity(0.1), in: Circle())
        .accessibilityHidden(true)
      Text(text)
        .font(.body).lineSpacing(4)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 3)
    }
    .padding(18)
    .frame(maxWidth: .infinity, alignment: .leading)
    .recipePanel(cornerRadius: 20)
  }

  private var cookingCard: some View {
    VStack(alignment: .leading, spacing: 24) {
      HStack(spacing: 10) {
        Text(String(format: "%02d", number))
          .font(.system(.title2, design: .rounded, weight: .bold))
          .monospacedDigit()
          .foregroundStyle(SazliTheme.terracotta)
          .frame(minWidth: 56, minHeight: 56)
          .background(
            SazliTheme.terracotta.opacity(0.11),
            in: RoundedRectangle(cornerRadius: 18))
        Text("STEP \(number)")
          .font(.caption.weight(.semibold)).tracking(1.3)
          .foregroundStyle(SazliTheme.terracotta)
      }
      .accessibilityHidden(true)
      Text(text)
        .font(.largeTitle.weight(.medium))
        .lineSpacing(6)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(24)
    .frame(maxWidth: .infinity, minHeight: 220, alignment: .topLeading)
    .recipePanel()
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
