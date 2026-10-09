import Combine
import Foundation

@MainActor
final class ContinentTopFiguresViewModel: ObservableObject {

    @Published private(set) var isLoading = false
    @Published private(set) var figures: [HistoricalFigure] = []
    @Published private(set) var errorMessage: String?

    private var currentContinentID: String?

    func load(
        for continent: Continent,
        repository: FigureCacheRepository
    ) {
        let continentID = continent.id
        currentContinentID = continentID
        errorMessage = nil

        let seededIDs = ContinentFigureIDs.ids(
            for: continentID
        )

        guard !seededIDs.isEmpty else {
            figures = []
            isLoading = false
            errorMessage = "No figures found."
            return
        }

        // 1. Load whatever is already cached.
        let cachedFigures =
            (try? repository.fetchFigures(
                withIDs: seededIDs
            )) ?? []

        // Show cached figures immediately.
        figures = cachedFigures

        // 2. Work out which figures are missing.
        let cachedIDs = Set(
            cachedFigures.map(\.id)
        )

        let missingIDs = seededIDs.filter {
            !cachedIDs.contains($0)
        }

        // Everything is already cached.
        guard !missingIDs.isEmpty else {
            isLoading = false
            return
        }

        // Only show a full loading state when there is
        // nothing available locally.
        isLoading = cachedFigures.isEmpty

        // 3. Fetch only the missing figures.
        WikidataAPI.fetchFigures(
            withIDs: missingIDs
        ) { [weak self] fetchedFigures in
            guard let self else {
                return
            }

            guard currentContinentID == continentID else {
                return
            }

            // 4. Save newly fetched figures.
            do {
                try repository.saveAll(
                    fetchedFigures
                )
            } catch {
                print(
                    "Failed to cache continent figures: \(error)"
                )
            }

            // 5. Reload from SwiftData so the final array
            // follows the seeded order.
            let updatedFigures =
                (try? repository.fetchFigures(
                    withIDs: seededIDs
                )) ?? []

            figures = updatedFigures
            isLoading = false

            if updatedFigures.isEmpty {
                errorMessage = "No figures found."
            }
        }
    }
}
