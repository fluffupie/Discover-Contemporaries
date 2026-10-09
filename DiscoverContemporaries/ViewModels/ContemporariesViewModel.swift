import Combine
import Foundation

@MainActor
final class ContemporariesViewModel: ObservableObject {

    @Published private(set) var figures: [ContemporaryFigure] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private var currentFigureID: String?

    func load(
        for figure: HistoricalFigure,
        repository: FigureCacheRepository
    ) {
        currentFigureID = figure.id
        isLoading = true
        errorMessage = nil

        ContemporaryService.fetchContemporaries(
            for: figure,
            repository: repository
        ) { [weak self] results in
            guard let self else {
                return
            }

            guard self.currentFigureID == figure.id else {
                return
            }

            self.figures = results
            self.isLoading = false

            if results.isEmpty {
                self.errorMessage = "No contemporaries found."
            }
        }
    }
}
