import SwiftUI

struct RegionView: View {
    private let continents = [
        Continent(id: "Q15", name: "Africa"),
        Continent(id: "Q48", name: "Asia"),
        Continent(id: "Q46", name: "Europe"),
        Continent(id: "Q49", name: "North America"),
        Continent(id: "Q18", name: "South America"),
        Continent(id: "Q538", name: "Oceania"),
        Continent(id: "Q51", name: "Antarctica"),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                ForEach(continents, id: \.id) { continent in
                    NavigationLink {
                        ContinentTopFiguresView(continent: continent)
                    } label: {
                        RegionRow(continent: continent)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .background(Color.appBackground)
        .navigationTitle("Region")
        .navigationBarTitleDisplayMode(.inline)
    }

    private struct RegionRow: View {
        let continent: Continent

        @State private var isLoading = false
        @State private var figures: [HistoricalFigure] = []

        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 14) {
                    Image(systemName: "globe.americas.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.tealButton)
                        .frame(width: 44, height: 44)

                    Text(continent.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.secondaryText)
                }

                Group {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else if !figures.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(figures) { figure in
                                    VStack(spacing: 10) {
                                        PortraitImage(
                                            imageName: figure.imageName,
                                            imageURL: figure.imageURL
                                        )
                                        .frame(width: 70, height: 70)
                                        .clipShape(
                                            RoundedRectangle(cornerRadius: 5)
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .task {
                await load()
            }
        }

        @MainActor
        private func load() async {
            guard figures.isEmpty else { return }
            isLoading = true
            WikidataAPI.fetchTopFigures(forContinentID: continent.id) {
                results in
                self.isLoading = false
                self.figures = Array(results.prefix(4))
            }
        }
    }
}
