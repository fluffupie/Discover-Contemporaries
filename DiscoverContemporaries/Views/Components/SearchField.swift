
import SwiftUI

/// A reusable search field for entering historical figure names.
///
/// Supports Dynamic Type and provides an accessible clear button
/// when the search field contains text.
struct SearchField: View {

    /// The text entered into the search field.
    @Binding var searchText: String

    /// The user's preferred Dynamic Type size.
    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    /// The search field and its associated controls.
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.secondaryText)
                .accessibilityHidden(true)

            TextField("Search figures", text: $searchText)
                .font(.body)
                .foregroundStyle(Color.primaryText)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .accessibilityLabel("Search historical figures")

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.secondaryText)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
                .accessibilityHint("Removes the current search text")
            }
        }
        .padding(.horizontal, 12)
        .frame(
            minHeight: dynamicTypeSize.isAccessibilitySize ? 56 : 44
        )
        .background(Color.white)
        .clipShape(
            RoundedRectangle(cornerRadius: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    Color.black.opacity(0.06),
                    lineWidth: 1
                )
        )
    }
}

#Preview("Search Field") {
    @Previewable @State var text = ""

    return VStack(spacing: 16) {
        SearchField(searchText: $text)
            .padding()
            .background(Color.appBackground)

        SearchField(
            searchText: .constant("Leonardo da Vinci")
        )
        .padding()
        .background(Color.appBackground)
    }
    .padding()
}
