import SwiftUI

struct JobsView: View {
    var body: some View {
        VStack(spacing: 16) {
            // TODO: Replace with Wikidata occupation facets when figure detail fetching exists.
            MigrationPlaceholderRow(
                icon: "briefcase.fill",
                title: "Jobs unavailable",
                detail: "Wikidata occupation facets are not implemented yet."
            )

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .background(Color.appBackground)
        .navigationTitle("Jobs")
        .navigationBarTitleDisplayMode(.inline)
    }
}
