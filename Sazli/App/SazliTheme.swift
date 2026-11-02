import SwiftUI

enum SazliTheme {
  static let terracotta = Color("Terracotta")
  static let coral = Color("Coral")
  static let orange = Color("WarmOrange")
  static let olive = Color("Olive")
  static let background = Color("Cream")
  static let surface = Color("Surface")
}

enum SazliLayout {
  // Use the available scene width so folds, rotation, and resized windows adapt live.
  static let columnBreakpoint: CGFloat = 640
  static let contentWidth: CGFloat = 1_080
  static let actionWidth: CGFloat = 480
}

extension View {
  func sazliScreen() -> some View {
    scrollContentBackground(.hidden)
      .background(SazliTheme.background)
  }
}
