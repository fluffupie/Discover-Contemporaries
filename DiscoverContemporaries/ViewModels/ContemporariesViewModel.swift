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

    private var currentFigureID: String?

    func load(
        for figure: HistoricalFigure
    ) {
        currentFigureID = figure.id

        isLoading = true
        errorMessage = nil

        let requestedFigureID = figure.id

        WikidataAPI.fetchContemporaries(
            for: figure
        ) { [weak self] figures in
            guard let self else {
                return
            }

            guard currentFigureID == requestedFigureID else {
                return
            }

            self.figures = figures
            self.isLoading = false
            self.errorMessage = figures.isEmpty
                ? "No contemporaries found."
                : nil
        }
    }
}
