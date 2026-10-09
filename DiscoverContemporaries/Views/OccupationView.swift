import Combine
import SwiftData
import SwiftUI

// MARK: - Occupation View

/// A view that allows users to explore historical figures by occupation.
///
/// Displays a list of predefined occupation categories.
struct OccupationView: View {

    /// Represents an occupation category available for exploration.
    struct Occupation: Identifiable {
        let id: String /// The unique Wikidata identifier of the occupation.
        let name: String
        let systemImage: String /// The SF Symbol representing the occupation.
    }

    /// The predefined occupation categories available for browsing.
    private let occupations: [Occupation] = [
        Occupation(
            id: "Q82955",
            name: "Politician",
            systemImage: "person.2.wave.2.fill"
        ),
        Occupation(
            id: "Q901",
            name: "Scientist",
            systemImage: "atom"
        ),
        Occupation(
            id: "Q483501",
            name: "Artist",
            systemImage: "paintpalette.fill"
        ),
        Occupation(
            id: "Q639669",
            name: "Musician",
            systemImage: "music.note"
        ),
        Occupation(
            id: "Q33999",
            name: "Actor",
            systemImage: "theatermasks.fill"
        ),
        Occupation(
            id: "Q177220",
            name: "Singer",
            systemImage: "mic.fill"
        ),
        Occupation(
            id: "Q11696",
            name: "Monarch",
            systemImage: "crown.fill"
        )
    ]

    var body: some View {
        List(occupations) { occupation in
            NavigationLink {
                OccupationTopFiguresView(
                    occupation: occupation
                )
            } label: {
                Label(
                    occupation.name,
                    systemImage: occupation.systemImage
                )
            }
        }
        .listStyle(.automatic)
        .scrollContentBackground(.automatic)
        .background(Color.appBackground)
        .navigationTitle("Occupations")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Occupation Top Figures

/// A view that displays historical figures associated with a selected occupation.
///
/// Loads predefined figures through ``OccupationTopFiguresViewModel``
/// and presents the results in a navigable list.
///
/// Users can select a figure to open their ``ProfileView``.
///
/// The view handles four states:
/// - Loading: Displays a progress indicator when no cached figures are available.
/// - Error: Displays an error message when loading produces no figures.
/// - Empty: Indicates that no figures were found.
/// - Success: Displays the available historical figures.
///
/// Cached figures remain visible while missing figures are being fetched.
private struct OccupationTopFiguresView: View {

    /// The occupation whose historical figures are being displayed.
    let occupation: OccupationView.Occupation

    /// The SwiftData model context used to initialise the cache repository.
    @Environment(\.modelContext)
    private var modelContext

    /// The view model responsible for loading and managing occupation figures.
    @StateObject
    private var model = OccupationTopFiguresViewModel()

    var body: some View {
        Group {
            if model.figures.isEmpty && model.isLoading {
                ProgressView()

            } else if let errorMessage = model.errorMessage,
                      model.figures.isEmpty {

                ContentUnavailableView(
                    "Unable to load figures",
                    systemImage: "exclamationmark.triangle",
                    description: Text(errorMessage)
                )

            } else if model.figures.isEmpty {
                ContentUnavailableView(
                    "No figures found",
                    systemImage: "person.crop.circle.badge.questionmark"
                )

            } else {
                figuresList
            }
        }
        .background(Color.appBackground)
        .navigationTitle(occupation.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            let repository = FigureCacheRepository(
                context: modelContext
            )

            model.load(
                for: occupation,
                repository: repository
            )
        }
    }

    private var figuresList: some View {
        List(model.figures) { figure in
            NavigationLink {
                ProfileView(
                    figure: figure
                )
            } label: {
                FigureList(
                    name: figure.name,
                    subtitle: figure.subtitle,
                    imageName: figure.imageName,
                    imageURL: figure.imageURL
                )
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
    }
}

// MARK: - View Model

@MainActor
final class OccupationTopFiguresViewModel: ObservableObject {

    @Published private(set)
    var isLoading = false

    @Published private(set)
    var figures: [HistoricalFigure] = []

    @Published private(set)
    var errorMessage: String?

    private var currentOccupationID: String?

    func load(
        for occupation: OccupationView.Occupation,
        repository: FigureCacheRepository
    ) {
        let occupationID = occupation.id

        currentOccupationID = occupationID
        errorMessage = nil

        let seededIDs = OccupationFigureSeeds.ids(
            for: occupationID
        )

        guard !seededIDs.isEmpty else {
            figures = []
            isLoading = false
            errorMessage = "No figures found."
            return
        }

        // 1. Load anything already stored in SwiftData.
        let cachedFigures =
            (try? repository.fetchFigures(
                withIDs: seededIDs
            )) ?? []

        // Show cached figures immediately.
        figures = cachedFigures

        // 2. Determine which seeded figures are missing.
        let cachedIDs = Set(
            cachedFigures.map(\.id)
        )

        let missingIDs = seededIDs.filter {
            !cachedIDs.contains($0)
        }

        // 3. Nothing else needs to be downloaded.
        guard !missingIDs.isEmpty else {
            isLoading = false
            return
        }

        // Only block the whole screen if there is
        // nothing available locally yet.
        isLoading = cachedFigures.isEmpty

        // 4. Fetch only missing figures.
        WikidataAPI.fetchFigures(
            withIDs: missingIDs
        ) { [weak self] fetchedFigures in
            guard let self else {
                return
            }

            guard currentOccupationID == occupationID else {
                return
            }

            // 5. Cache downloaded figures.
            do {
                try repository.saveAll(
                    fetchedFigures
                )
            } catch {
                print(
                    "Failed to cache occupation figures: \(error)"
                )
            }

            // 6. Reload from SwiftData in seed order.
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

#Preview {
    NavigationStack {
        OccupationView()
    }
}
