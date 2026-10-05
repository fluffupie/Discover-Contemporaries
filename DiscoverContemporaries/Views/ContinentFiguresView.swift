import SwiftUI

struct ContinentFiguresView: View {
    private let continents = [
        Continent(id: "Q15", name: "Africa"),
        Continent(id: "Q48", name: "Asia"),
        Continent(id: "Q46", name: "Europe"),
        Continent(id: "Q18", name: "South America"),
        Continent(id: "Q49", name: "North America"),
        Continent(id: "Q538", name: "Oceania"),
        Continent(id: "Q51", name: "Antarctica")
    ]

    var body: some View {
        List(continents) { continent in
            NavigationLink(value: continent) {
                Label(
                    continent.name,
                    systemImage: "globe.americas.fill"
                )
            }
        }
        .navigationDestination(for: Continent.self) { continent in
            ContinentTopFiguresView(continent: continent)
        }
        .navigationTitle("Continents")
    }
}
