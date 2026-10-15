import Combine
import Foundation
import OSLog

/// Manages loading and display state for a figure's contemporaries.
@MainActor
final class ContemporariesViewModel: ObservableObject {
    /// The contemporaries, closest in birth date first.
    @Published private(set) var figures: [ContemporaryFigure] = []

    /// Whether a load is in progress.
    @Published private(set) var isLoading = false

    /// A message for the empty or failed state, or `nil`.
    @Published private(set) var errorMessage: String?

    private var currentFigureID: String?
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "DiscoverContemporaries",
        category: "Contemporaries"
    )

    /// Loads contemporaries for a figure.
    ///
    /// Call from `.task(id: figure.id)` so a change of figure cancels the
    /// previous load. A cancelled load leaves the state to the newer one.
    ///
    /// - Parameters:
    ///   - figure: The figure whose contemporaries to load.
    ///   - repository: The repository used to read and cache figures.
    func load(
        for figure: HistoricalFigure,
        repository: FigureCacheRepository
    ) async {
        if currentFigureID != figure.id {
            figures = []
        }
        currentFigureID = figure.id
        isLoading = true
        errorMessage = nil

        do {
            let results = try await ContemporaryService.fetchContemporaries(
                for: figure,
                repository: repository
            )
            try Task.checkCancellation()

            figures = results
            isLoading = false
        } catch is CancellationError {
            // Superseded or the view went away. Don't touch state.
        } catch let error as URLError where error.code == .cancelled {
            // Same, surfaced by URLSession.
        } catch {
            logger.error("Failed to load contemporaries: \(error.localizedDescription)")
            figures = []
            isLoading = false
            errorMessage = String(localized: "Couldn't load contemporaries. Check your connection and try again.")
        }
    }
}
