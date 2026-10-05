import SwiftUI

struct Continent: Identifiable, Hashable {
    let id: String // Wikidata ID, e.g. Q15 (Africa)
    let name: String
}

struct ContinentFiguresView: View {
    private let continents: [Continent] = [
        Continent(id: "Q15", name: "Africa"),
        Continent(id: "Q48", name: "Asia"),
        Continent(id: "Q46", name: "Europe"),
        Continent(id: "Q18", name: "South America"),
        Continent(id: "Q49", name: "North America"),
        Continent(id: "Q538", name: "Oceania"),
        Continent(id: "Q51", name: "Antarctica")
    ]

    var body: some View {
        List(continents, id: \.id) { continent in
            NavigationLink(value: continent) {
                Label(continent.name, systemImage: "globe.americas.fill")
            }
        }
        .navigationDestination(for: Continent.self) { continent in
            ContinentTopFiguresView(continent: continent)
        }
        .navigationTitle("Continents")
    }
}

struct ContinentTopFiguresView: View {
    let continent: Continent

    @State private var isLoading = true
    @State private var figures: [HistoricalFigure] = []
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if figures.isEmpty {
                Text("No figures found.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                List(figures) { figure in
                    NavigationLink {
                        ProfileView(figure: figure)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(figure.name)
                                .font(.headline)
                            Text(figure.lifespan)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(continent.name)
        .task { load() }
    }

    private func load() {
        isLoading = true
        errorMessage = nil
        WikidataAPI.fetchTopFigures(forContinentID: continent.id) { results in
            self.isLoading = false
            self.figures = results
            if results.isEmpty {
                self.errorMessage = "No results found."
            }
        }
    }
}

#Preview {
    NavigationStack {
        ContinentFiguresView()
    }
}
