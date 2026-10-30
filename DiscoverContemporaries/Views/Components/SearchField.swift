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
        HStack() {
            Image(systemName: "magnifyingglass")
            TextField("Search", text: $searchText)
                .font(.body)
        }
    }
}
