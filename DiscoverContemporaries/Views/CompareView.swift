import SwiftUI

struct CompareView: View {
    var body: some View {
        VStack(spacing: 16) {
            // TODO: Restore comparison once full Wikidata figure detail fetching exists.
            VStack(spacing: 12) {
                MigrationPlaceholderRow(
                    icon: "person.2.fill",
                    title: "Comparison unavailable",
                    detail: "Full Wikidata figure details are not implemented yet."
                )

                Text("Search results currently show Wikidata matches only.")
                    .font(.caption)
                    .foregroundStyle(Color.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 12)
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(.horizontal, 24)
        .background(Color.appBackground)
        .navigationTitle("Compare")
        .navigationBarTitleDisplayMode(.inline)
    }
}
