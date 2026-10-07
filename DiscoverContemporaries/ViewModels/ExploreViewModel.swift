import Combine
import Foundation

@MainActor
final class ContinentTopFiguresViewModel: ObservableObject {

    @Published private(set) var isLoading = false
    @Published private(set) var figures: [HistoricalFigure] = []
    @Published private(set) var errorMessage: String?

    private var currentContinentID: String?

    func load(for continent: Continent) {
        currentContinentID = continent.id

        isLoading = true
        errorMessage = nil

        let requestedID = continent.id

        WikidataAPI.fetchTopFigures(
            forContinentID: requestedID
        ) { [weak self] results in
            guard let self else {
                return
            }

            guard currentContinentID == requestedID else {
                return
            }

            figures = results
            isLoading = false
            errorMessage = results.isEmpty
                ? "No results found."
                : nil
        }
    }
}
