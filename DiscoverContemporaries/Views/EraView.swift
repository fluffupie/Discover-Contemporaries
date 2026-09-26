import SwiftUI

struct EraView: View {
    var body: some View {
        VStack(spacing: 16) {
            // TODO: Replace with Wikidata-derived era grouping when full figure dates are loaded.
            MigrationPlaceholderRow(
                icon: "calendar",
                title: "Eras unavailable",
                detail: "Wikidata era grouping is not implemented yet."
            )

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .background(Color.appBackground)
        .h1NavigationTitle("Era")
    }
}
