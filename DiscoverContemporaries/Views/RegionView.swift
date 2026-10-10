import SwiftUI

// MARK: - Region View

/// A view that allows users to explore historical figures by geographical region.
///
/// Displays a list of predefined continents, including Africa, Asia, Europe, America, and Oceania.
///
/// Users can select a continent to navigate to ``ContinentTopFiguresView``
/// and discover historical figures associated with that region.
struct RegionView: View {

    private let continents = [
            Continent(
                id: "Q15",
                name: "Africa",
                systemImage: "globe.europe.africa.fill"
            ),
            Continent(
                id: "Q48",
                name: "Asia",
                systemImage: "globe.asia.australia.fill"
            ),
            Continent(
                id: "Q46",
                name: "Europe",
                systemImage: "globe.europe.africa.fill"
            ),
            Continent(
                id: "Q828",
                name: "Americas",
                systemImage: "globe.americas.fill"
            ),
            Continent(
                id: "Q538",
                name: "Oceania",
                systemImage: "globe.asia.australia.fill"
            )
        ]

    /// Displays the predefined continents in a navigable list.
    var body: some View {
            List(continents) { continent in
                NavigationLink {
                    ContinentTopFiguresView(
                        continent: continent
                    )
                } label: {
                    Label(
                        continent.name,
                        systemImage: continent.systemImage
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(continent.name)
                    .accessibilityValue("Explore figures in \(continent.name)")
                    .accessibilityHint("Opens top figures for this region")
                }
            }
            .navigationTitle("Regions")
            .navigationBarTitleDisplayMode(.inline)
        }
}
