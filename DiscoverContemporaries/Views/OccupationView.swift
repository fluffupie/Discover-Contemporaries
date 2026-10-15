import Combine
import SwiftData
import SwiftUI
import OSLog

// MARK: - Occupation View

/// A view that allows users to explore historical figures by occupation.
///
/// Displays a list of predefined occupation categories.
struct OccupationView: View {

    /// Represents an occupation category available for exploration.
    struct Occupation: Identifiable {
        /// The unique Wikidata identifier of the occupation.
        let id: String // Identifiable requires an id property.
        let name: String
        /// The SF Symbol representing the occupation.
        let systemImage: String
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
                .accessibilityElement(children: .combine)
                .accessibilityLabel(occupation.name)
                .accessibilityHint("Opens top figures for \(occupation.name)")
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

    @StateObject
    private var model = SeededFiguresViewModel()

    var body: some View {
        Group {
            if model.figures.isEmpty && model.isLoading {
                ProgressView("Loading…")
                    .accessibilityHint("Please wait while figures are loading.")

            } else if let errorMessage = model.errorMessage,
                      model.figures.isEmpty {

                ContentUnavailableView(
                    "Unable to load figures",
                    systemImage: "exclamationmark.triangle",
                    description: Text(errorMessage)
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Unable to load figures")
                .accessibilityValue(errorMessage)
                .accessibilityHint("Try again later or pull to refresh if available.")

            } else if model.figures.isEmpty {
                ContentUnavailableView(
                    "No figures found",
                    systemImage: "person.crop.circle.badge.questionmark"
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel("No figures found")
                .accessibilityHint("No matching historical figures were found for this occupation.")

            } else {
                figuresList
            }
        }
        .background(Color.appBackground)
        .navigationTitle(occupation.name)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: occupation.id) {
            let repository = FigureCacheRepository(context: modelContext)
            await model.load(
                key: occupation.id,
                seededIDs: OccupationFigureSeeds.ids(for: occupation.id),
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
                .accessibilityElement(children: .combine)
                .accessibilityLabel(figure.name)
                .accessibilityValue(figure.subtitle ?? figure.lifespan)
                .accessibilityHint("Opens profile")
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
    }
}

// MARK: - View Model

/// Manages loading and display state for an occupation's curated figures.
@MainActor
final class OccupationTopFiguresViewModel: ObservableObject {
    /// Whether a load is in progress with nothing cached to show.
    @Published private(set) var isLoading = false

    /// The figures, in the seeded order.
    @Published private(set) var figures: [HistoricalFigure] = []

    /// A message for the empty or failed state, or `nil`.
    @Published private(set) var errorMessage: String?

    private var currentOccupationID: String?
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "DiscoverContemporaries",
        category: "Occupations"
    )

    /// Loads the curated figures for an occupation.
    ///
    /// Cached figures appear immediately. Missing ones are fetched from
    /// Wikidata, saved to SwiftData, and the list is reloaded in seeded order.
    /// If the fetch fails, cached figures stay on screen.
    ///
    /// Call from `.task(id: occupation.id)` so a change of occupation cancels
    /// the previous load.
    func load(
        for occupation: OccupationView.Occupation,
        repository: FigureCacheRepository
    ) async {
        let occupationID = occupation.id
        if currentOccupationID != occupationID {
            figures = []
        }
        currentOccupationID = occupationID
        errorMessage = nil

        let seededIDs = OccupationFigureSeeds.ids(for: occupationID)
        guard !seededIDs.isEmpty else {
            figures = []
            isLoading = false
            errorMessage = String(localized: "No figures found.")
            return
        }

        // 1. Show whatever is already cached.
        let cached = (try? repository.fetchFigures(withIDs: seededIDs)) ?? []
        figures = cached

        let cachedIDs = Set(cached.map(\.id))
        let missingIDs = seededIDs.filter { !cachedIDs.contains($0) }

        guard !missingIDs.isEmpty else {
            isLoading = false
            return
        }

        // 2. Only block the screen when nothing is available locally.
        isLoading = cached.isEmpty

        do {
            // 3. Fetch, cache, and reload in seeded order.
            let fetched = try await WikidataAPI.fetchFiguresInBatches(withIDs: missingIDs)
            try Task.checkCancellation()

            do {
                try repository.saveAll(fetched)
            } catch {
                logger.error("Failed to cache occupation figures: \(error.localizedDescription)")
            }

            figures = (try? repository.fetchFigures(withIDs: seededIDs)) ?? cached + fetched
            isLoading = false
            if figures.isEmpty {
                errorMessage = String(localized: "No figures found.")
            }
        } catch is CancellationError {
            // Superseded or the view went away. Leave the state to the newer load.
        } catch let error as URLError where error.code == .cancelled {
            // Same, surfaced by URLSession.
        } catch {
            logger.error("Failed to load occupation figures: \(error.localizedDescription)")
            isLoading = false
            if cached.isEmpty {
                errorMessage = String(localized: "Couldn't load figures. Check your connection and try again.")
            }
        }
    }
}

#Preview {
    NavigationStack {
        OccupationView()
    }
}
