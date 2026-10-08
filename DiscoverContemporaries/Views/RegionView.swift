import SwiftUI

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
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Regions")
            .navigationBarTitleDisplayMode(.inline)
        }
}
