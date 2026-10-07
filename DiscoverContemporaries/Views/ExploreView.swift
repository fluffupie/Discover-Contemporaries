import SwiftUI

struct ExploreView: View {
    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {

            VStack(
                alignment: .leading,
                spacing: 24
            ) {
                LazyVGrid(
                    columns: columns,
                    spacing: 14
                ) {
                    NavigationLink {
                        RegionView()
                    } label: {
                        ExploreCard(
                            title: "By Region",
                            subtitle: "Explore figures around the world",
                            systemImage: "globe",
                            backgroundColor: .mintTile
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        EraView()
                    } label: {
                        ExploreCard(
                            title: "By Era",
                            subtitle: "Browse historical time periods",
                            systemImage: "calendar",
                            backgroundColor: .peachTile
                        )
                    }
                    .buttonStyle(.plain)
                }

                NavigationLink {
                    JobsView()
                } label: {
                    ExploreWideCard(
                        title: "By Occupation",
                        subtitle:
                            "Discover artists, scientists, rulers, writers and more",
                        systemImage: "paintpalette.fill",
                        backgroundColor: .lavenderTile
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .padding(.bottom, 32)

        }
        .background(Color.appBackground)
        .navigationTitle("Explore")
        .navigationBarTitleDisplayMode(.inline)
    }
}
