import Combine
import Foundation

@MainActor
final class ContinentTopFiguresViewModel: ObservableObject {
    @Published private(set) var isLoading = false
    @Published private(set) var figures: [HistoricalFigure] = []
    @Published private(set) var errorMessage: String?

    func load(for continent: Continent) {
        isLoading = true
        errorMessage = nil

        WikidataAPI.fetchTopFigures(
            forContinentID: continent.id
        ) { [weak self] results in
            guard let self else { return }

            figures = results
            isLoading = false

            if results.isEmpty {
                errorMessage = "No results found."
            }
        }
    }
}
