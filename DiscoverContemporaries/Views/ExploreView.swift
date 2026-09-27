import SwiftUI

struct ExploreView: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 18), count: 2), spacing: 10) {
                    NavigationLink {
                        RegionView()
                    } label: {
                        CategoryTile(title: "Region", systemImage: "globe.americas.fill", color: .mintTile)
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        EraView()
                    } label: {
                        CategoryTile(title: "Era", systemImage: "27.calendar", color: .peachTile)
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        JobsView()
                    } label: {
                        CategoryTile(title: "Jobs", systemImage: "paintpalette.fill", color: .lavenderTile)
                    }
                    .buttonStyle(.plain)
                }
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
