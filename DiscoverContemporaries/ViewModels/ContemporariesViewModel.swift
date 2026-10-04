import Combine
import Foundation

@MainActor
final class ContemporariesViewModel: ObservableObject {

    @Published private(set)
    var figures: [ContemporaryFigure] = []

    @Published private(set)
    var isLoading = false

    @Published private(set)
    var errorMessage: String?

    func load(
        for figure: HistoricalFigure
    ) {
        isLoading = true
        errorMessage = nil

        WikidataAPI.fetchContemporaries(
            for: figure
        ) { [weak self] figures in
            guard let self else {
                return
            }

            self.figures = figures
            self.isLoading = false

            if figures.isEmpty {
                self.errorMessage =
                    "No contemporaries found."
            }
        }
    }
}
