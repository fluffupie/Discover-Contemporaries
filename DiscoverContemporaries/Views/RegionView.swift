import SwiftData
import SwiftUI

struct RegionView: View {
    @Query(sort: \CachedHistoricalFigure.name) private var cachedFigures: [CachedHistoricalFigure]

    private var regions: [RegionSummary] {
        let counts = cachedFigures.reduce(into: [String: Int]()) { result, figure in
            guard let birthPlace = figure.birthPlace, !birthPlace.isEmpty else {
                return
            }

            result[birthPlace, default: 0] += 1
        }

        return counts
            .map { RegionSummary(name: $0.key, count: $0.value) }
            .sorted { first, second in
                if first.count == second.count {
                    return first.name < second.name
                }

                return first.count > second.count
            }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                if regions.isEmpty {
                    MigrationPlaceholderRow(
                        icon: "globe.americas.fill",
                        title: "Regions unavailable",
                        detail: "No cached countries found yet."
                    )
                } else {
                    ForEach(regions) { region in
                        CategoryListRow(
                            icon: "globe.americas.fill",
                            title: region.name,
                            detail: region.countText
                        )
                    }
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
}

private struct RegionSummary: Identifiable {
    let name: String
    let count: Int

    var id: String { name }

    var countText: String {
        count == 1 ? "1 figure" : "\(count) figures"
    }
}
