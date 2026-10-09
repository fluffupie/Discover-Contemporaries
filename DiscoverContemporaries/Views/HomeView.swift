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

    init(model: HomeViewModel? = nil) {
        _model = StateObject(
            wrappedValue: model ?? HomeViewModel()
        )
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

                SearchField(
                    searchText: $model.searchText
                )
                .onSubmit {
                    model.searchFigures()
                }

                if model.hasSearchQuery {
                    SearchResultsSection(
                        isLoading: model.isLoading,
                        errorMessage: model.errorMessage,
                        results: model.searchResults
                    )
                } else {
                    ExploreFiguresSection(
                        figures: model.defaultFigures(
                            from: cachedFigures
                        )
                    )

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
                .foregroundStyle(Color.primaryText)

            DefaultCachedFiguresGrid(
                figures: figures
            )
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
                .foregroundStyle(Color.primaryText)

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
                .font(
                    .system(
                        size: 14,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    Color.primaryText
                )
                .lineLimit(1)
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
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 30)

            } else if let errorMessage {
                Text(errorMessage)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.secondaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 30)

            } else if results.isEmpty {
                EmptySearchView()

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

// MARK: - Default Figures on Homepage

private struct DefaultCachedFiguresGrid: View {

    let figures: [HistoricalFigure]

    private let columns = [
        GridItem(
            .flexible(),
            spacing: 12
        ),
        GridItem(
            .flexible(),
            spacing: 12
        ),
    ]

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
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
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
            .font(
                .system(
                    size: 26,
                    weight: .semibold,
                    design: .serif
                )
            )
            .foregroundStyle(Color.primaryText)
            .lineSpacing(1)
            .lineLimit(2)
            .minimumScaleFactor(0.7)
            .multilineTextAlignment(.leading)

            Text(
                "Explore history through overlapping lifespans."
            )
            .font(
                .system(
                    size: 14,
                    weight: .regular
                )
            )
            .foregroundStyle(Color.secondaryText)
            .padding(.top, 2)
        }
        .padding(.bottom, 4)
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
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

@MainActor
private func makeHomePreviewContainer() -> ModelContainer {
    let schema = Schema([
        CachedHistoricalFigure.self
    ])

    let configuration = ModelConfiguration(
        isStoredInMemoryOnly: true
    )

    do {
        return try ModelContainer(
            for: schema,
            configurations: configuration
        )
    } catch {
        fatalError(
            "Failed to create preview ModelContainer: \(error)"
        )
    }
}

@MainActor
private let homePreviewContainer =
    makeHomePreviewContainer()

#Preview {
    NavigationStack {
        HomeView(
            model: HomeViewModel()
        )
    }
    .modelContainer(
        homePreviewContainer
    )
}
