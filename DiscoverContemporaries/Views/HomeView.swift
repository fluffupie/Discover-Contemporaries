import SwiftData
import SwiftUI

// MARK: - Home View

/// The main screen for discovering and searching historical figures.
///
/// Provides access to historical figures through:
/// - Search: Find figures using Wikidata search results.
/// - Explore: Browse default figures stored in the local SwiftData cache.
/// - Recently Viewed: Revisit previously explored historical figures.

@MainActor
struct HomeView: View {
    /// The SwiftData model context used to seed historical figures.
    @Environment(\.modelContext) private var modelContext

    /// The view model responsible for search and homepage content.
    @StateObject private var model: HomeViewModel

    /// Historical figures retrieved from SwiftData, sorted by name.
    @Query(sort: \CachedHistoricalFigure.name)
    private var cachedFigures: [CachedHistoricalFigure]
    @State private var searchText: String = ""

    init(model: HomeViewModel? = nil) {
        _model = StateObject(
            wrappedValue: model ?? HomeViewModel()
        )
    }

    // MARK: - Header

    private struct HeaderView: View {

        var body: some View {
            VStack(
                alignment: .leading,
                spacing: 10
            ) {
                Text(
                    "Who lived at\nthe same time?"
                )
                .font(.largeTitle)
                .fontWeight(.bold)
                .fontDesign(.serif)
                .foregroundStyle(Color.black.opacity(0.9))
                .multilineTextAlignment(.leading)
                .accessibilityAddTraits(.isHeader)

                Text(
                    "Explore history through overlapping lifespans."
                )
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Color.black.opacity(0.65))
                .padding(.top, 2)
            }
            .padding(.bottom, 4)
        }
    }

    private var featuredFigures: [HistoricalFigure] {
        let figuresByID = Dictionary(
            uniqueKeysWithValues: cachedFigures.map {
                ($0.wikidataID, $0.historicalFigure)
            }
        )

        var result = FeaturedFigureSeeds.ids.compactMap {
            figuresByID[$0]
        }

        if let index = result.firstIndex(where: { $0.name == "Marie Curie" }) {
            let marie = result.remove(at: index)
            result.insert(marie, at: 0)
        }

        return result
    }

    /// When a search query is active, search results replace the
    /// default exploration and recently viewed sections.
    ///
    /// Otherwise, the screen displays cached historical figures
    /// and a recently viewed section when applicable.
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(
                alignment: .leading,
                spacing: 24
            ) {
                HeaderView()

                if model.hasSearchQuery {
                    SearchResultsSection(
                        isLoading: model.isLoading,
                        errorMessage: model.errorMessage,
                        results: model.searchResults
                    )
                } else {

                    let defaultFigures = model.defaultFigures(
                        from: cachedFigures
                    )

                    let exploreFigures = defaultFigures.filter {
                        !FeaturedFigureSeeds.ids.contains($0.id)
                    }

                    FeaturedFiguresSection(figures: featuredFigures)

                    ExploreFiguresSection(figures: exploreFigures)

                    let recentFigures = model.recentlyViewedFigures(
                        from: cachedFigures
                    )

                    if !recentFigures.isEmpty {
                        RecentlyViewedSection(
                            figures: recentFigures
                        )
                    }
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 14)
            .padding(.bottom, 24)
        }
        .background(Color.appBackground)
        .navigationTitle("Home")
        .searchable(text: $model.searchText, prompt: "Search for a figure...")
        .onSubmit(of: .search) {
            model.searchFigures()
        }
        // todo: .textInputAutocapitalization(.words)
        //        .autocorrectionDisabled()
        //        .submitLabel(.search)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            setupHome()
        }
    }

    // MARK: - Setup

    /// Seeds the local SwiftData cache with default historical figures
    /// when required.
    ///
    /// Uses ``FigureDataSeeder`` to populate the cache and logs
    /// an error if seeding fails.
    private func setupHome() {
        do {
            try FigureDataSeeder.seedIfNeeded(
                context: modelContext
            )
        } catch {
            print(
                "Failed to seed figures: \(error)"
            )
        }
    }
}

// MARK: - Featured Figures

private struct FeaturedFiguresSection: View {

    let figures: [HistoricalFigure]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Featured figures")
                .font(.headline)
                .foregroundStyle(Color.primaryText)

            PageView(figures: figures)
                .aspectRatio(3 / 2, contentMode: .fit)
                .clipShape(
                    RoundedRectangle(cornerRadius: 12)
                )
        }
    }
}

// MARK: - Explore Figures

private struct ExploreFiguresSection: View {

    /// The historical figures displayed in the exploration section.
    let figures: [HistoricalFigure]

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            Text("Explore figures")
                .font(.headline)
                .foregroundStyle(Color.black.opacity(0.85))

            DefaultCachedFiguresGrid(
                figures: figures
            )
        }
    }
}

// MARK: - Default Figures on Homepage
private struct DefaultCachedFiguresGrid: View {

    /// The historical figures displayed in the grid.
    let figures: [HistoricalFigure]

    /// The user's preferred Dynamic Type size.
    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

    /// The adaptive grid layout for historical figure cards.
    ///
    /// Displays two columns at standard text sizes and
    /// one column at accessibility text sizes.
    private var columns: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? 1 : 2

        return Array(
            repeating: GridItem(.flexible(), spacing: 12),
            count: count
        )
    }

    var body: some View {
        if figures.isEmpty {
            EmptySearchView()
        } else {
            LazyVGrid(
                columns: columns,
                spacing: 12
            ) {
                ForEach(figures) { figure in
                    NavigationLink {
                        ProfileView(
                            figure: figure
                        )
                    } label: {
                        FigureCard(
                            figure: figure
                        )
                        .accessibilityHint(
                            "Opens historical figure profile"
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Recently Viewed

/// A section displaying historical figures previously viewed by the user.
///
/// Presents figures in a horizontally scrollable collection.
/// Selecting a figure navigates to its ``ProfileView``.
private struct RecentlyViewedSection: View {
    /// The historical figures to display in the recently viewed section.
    let figures: [HistoricalFigure]

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            Text("Recently viewed")
                .font(.headline)
                .foregroundStyle(Color.black.opacity(0.9))

            ScrollView(
                .horizontal,
                showsIndicators: false
            ) {
                HStack(spacing: 12) {
                    ForEach(figures) { figure in
                        NavigationLink {
                            ProfileView(
                                figure: figure
                            )
                        } label: {
                            RecentlyViewedCard(
                                figure: figure
                            )
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel(figure.name)
                            .accessibilityValue(
                                figure.descriptionText ?? figure.name
                            )
                            .accessibilityHint("Opens profile")
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Recently Viewed Card

private struct RecentlyViewedCard: View {

    let figure: HistoricalFigure

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            PortraitImage(
                imageName: figure.imageName,
                imageURL: figure.imageURL
            )
            .frame(
                width: 120,
                height: 120
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 10
                )
            )

            Text(figure.name)
                .font(.subheadline)
                .foregroundStyle(Color.black.opacity(0.9))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: 120)
    }
}

// MARK: - Search Results

/// A section displaying search results returned from Wikidata.
///
/// Handles four possible states:
/// - Loading: Displays a progress indicator.
/// - Error: Displays an error message.
/// - Empty: Displays an empty search placeholder.
/// - Success: Displays matching historical figures.
///
/// Search results are presented using ``WikidataSearchResultRow``.
private struct SearchResultsSection: View {

    let isLoading: Bool
    let errorMessage: String?
    let results: [WikidataSearchResult]

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            Text("Search results")
                .font(.headline)
                .foregroundStyle(Color.primaryText)

            if isLoading {
                ProgressView("Searching…")
                    .accessibilityHint("Please wait while results are loading")
                    .frame(maxWidth: .infinity)
                    .padding(.top, 30)

            } else if let errorMessage {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundStyle(Color.black.opacity(0.65))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 30)
                    .accessibilityLabel("Search error")
                    .accessibilityValue(errorMessage)

            } else if results.isEmpty {
                EmptySearchView()
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("No matching figures")
                    .accessibilityHint(
                        "Try searching by name, role, era, or lifespan."
                    )

            } else {
                VStack(spacing: 12) {
                    ForEach(results) { result in
                        WikidataSearchResultRow(
                            result: result
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Search Result Row
private struct WikidataSearchResultRow: View {

    let result: WikidataSearchResult

    private var figure: HistoricalFigure {
        HistoricalFigure(
            id: result.id,
            name: result.label,
            descriptionText: result.description,
            gender: nil,
            birthPlace: nil,
            birthDate: nil,
            deathDate: nil,
            occupations: [],
            movements: [],
            imageURL: result.imageURL,
            imageName: nil
        )
    }

    var body: some View {
        NavigationLink {
            ProfileView(
                figure: figure
            )
        } label: {
            FigureList(
                name: result.label,
                subtitle: result.description,
                imageName: nil,
                imageURL: result.imageURL
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel(result.label)
            .accessibilityValue(result.description ?? "No description")
            .accessibilityHint("Opens profile")
        }
        .buttonStyle(.plain)
    }
}
