import SwiftUI

struct JobsView: View {
    struct Occupation: Identifiable {
        let id: String // Wikidata ID for the occupation root
        let name: String
        let systemImage: String
    }

    private let occupations: [Occupation] = [
        Occupation(id: "Q82955", name: "Politician", systemImage: "person.2.wave.2.fill"),
        Occupation(id: "Q901", name: "Scientist", systemImage: "atom"),
        Occupation(id: "Q10800557", name: "Entertainer", systemImage: "theatermasks.fill"),
        Occupation(id: "Q11696", name: "Monarch", systemImage: "crown.fill")
    ]

    var body: some View {
        List(occupations) { occ in
            NavigationLink {
                OccupationTopFiguresView(occupation: occ)
            } label: {
                Label(occ.name, systemImage: occ.systemImage)
            }
        }
        .navigationTitle("Jobs")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct OccupationTopFiguresView: View {
    let occupation: JobsView.Occupation

    @State private var isLoading = true
    @State private var figures: [HistoricalFigure] = []
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
            } else if let errorMessage {
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
        .navigationTitle(occupation.name)
        .task { load() }
    }

    private func load() {
        isLoading = true
        errorMessage = nil
        WikidataAPI.fetchTopFigures(forOccupationID: occupation.id) { results in
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
        JobsView()
    }
}

