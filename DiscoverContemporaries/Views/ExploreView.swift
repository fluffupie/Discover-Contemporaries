import SwiftUI

struct ExploreView: View {

    private let columns = [
        GridItem(.flexible(), spacing: 18),
        GridItem(.flexible(), spacing: 18)
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(
                columns: columns,
                spacing: 10
            ) {
                NavigationLink {
                    RegionView()
                } label: {
                    CategoryTile(
                        title: "Region",
                        systemImage: "globe",
                        color: .mintTile
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    EraView()
                } label: {
                    CategoryTile(
                        title: "Era",
                        systemImage: "calendar",
                        color: .peachTile
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    JobsView()
                } label: {
                    CategoryTile(
                        title: "Jobs",
                        systemImage: "paintpalette.fill",
                        color: .lavenderTile
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 26)
            .padding(.top, 14)
            .padding(.bottom, 26)
        }
        .background(Color.appBackground)
        .navigationTitle("Explore")
        .navigationBarTitleDisplayMode(.inline)
    }
}
