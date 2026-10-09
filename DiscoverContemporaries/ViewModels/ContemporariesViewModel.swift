import Combine
import Foundation

/// Manages loading and display state for a historical figure's contemporaries.
@MainActor
final class ContemporariesViewModel: ObservableObject {

    @Published private(set) var figures: [ContemporaryFigure] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private var currentFigureID: String?

    /// Loads contemporaries for the specified historical figure.
    ///
    /// Results are retrieved through `ContemporaryService` using the supplied
    /// figure cache repository. Results from outdated requests are ignored.
    ///
    /// - Parameters:
    ///   - figure: The historical figure whose contemporaries should be loaded.
    ///   - repository: The repository used to access cached historical figures.
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
