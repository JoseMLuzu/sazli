import SwiftUI

struct RatingStars: View {
    let rating: Int
    var onSelect: ((Int) -> Void)?

    var body: some View {
        HStack(spacing: onSelect == nil ? 3 : 6) {
            ForEach(1...5, id: \.self) { value in
                if let onSelect {
                    Button { onSelect(value) } label: {
                        star(value).font(.title2).frame(minWidth: 44, minHeight: 44)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(value) of 5 stars")
                    .accessibilityAddTraits(rating == value ? .isSelected : [])
                } else {
                    star(value)
                }
            }
        }
        .accessibilityElement(children: onSelect == nil ? .ignore : .contain)
        .accessibilityLabel(onSelect == nil ? (rating == 0 ? "Not rated" : "\(rating) of 5 stars") : "Rating")
    }

    private func star(_ value: Int) -> some View {
        Image(systemName: value <= rating ? "star.fill" : "star")
            .foregroundStyle(value <= rating ? SazliTheme.terracotta : .secondary)
    }
}
