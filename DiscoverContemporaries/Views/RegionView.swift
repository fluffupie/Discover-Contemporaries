import SwiftUI

struct RegionView: View {
    var body: some View {
        VStack(spacing: 16) {
            // TODO: Replace with Wikidata-derived region grouping when full figure details are loaded.
            MigrationPlaceholderRow(
                icon: "globe.americas.fill",
                title: "Regions unavailable",
                detail: "Wikidata region grouping is not implemented yet."
            )

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .background(Color.appBackground)
        .navigationTitle("Region")
        .navigationBarTitleDisplayMode(.inline)
    }
}
