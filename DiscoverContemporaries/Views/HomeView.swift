import SwiftData
import SwiftUI

@MainActor
struct HomeView: View {

    @Environment(\.modelContext) private var modelContext

    @StateObject private var model: HomeViewModel

    @Query(sort: \CachedHistoricalFigure.name)
    private var cachedFigures: [CachedHistoricalFigure]

    init(model: HomeViewModel? = nil) {
        _model = StateObject(
            wrappedValue: model ?? HomeViewModel()
        )
    }

    // MARK: - State

    private var isSearching: Bool {
        !model.searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
    }

    // MARK: - Default Figures

    private let defaultFigureIDs = [
        "Q7259",  // Ada Lovelace
        "Q762",   // Leonardo da Vinci
        "Q2831",  // Michael Jackson
        "Q9682"   // Elizabeth II
    ]

    private var defaultFigures: [HistoricalFigure] {
        let figuresByID = Dictionary(
            uniqueKeysWithValues: cachedFigures.map {
                ($0.wikidataID, $0)
            }
        )

        return defaultFigureIDs.compactMap {
            figuresByID[$0]?.toHistoricalFigure()
        }
    }

    // MARK: - Recently Viewed

    private var recentlyViewedFigures: [HistoricalFigure] {
        cachedFigures
            .filter {
                !defaultFigureIDs.contains($0.wikidataID)
            }
            .sorted {
                $0.lastViewedAt > $1.lastViewedAt
            }
            .prefix(5)
            .map {
                $0.toHistoricalFigure()
            }
    }

    // MARK: - Body

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

                if isSearching {
                    SearchResultsSection(
                        isLoading: model.isLoading,
                        errorMessage: model.errorMessage,
                        results: model.searchResults
                    )
                } else {
                    ExploreFiguresSection(
                        figures: defaultFigures
                    )

                    if !recentlyViewedFigures.isEmpty {
                        RecentlyViewedSection(
                            figures: recentlyViewedFigures
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

private struct RecentlyViewedSection: View {

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
        )
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
            imageURL: nil,
            imageName: nil
        )
    }

    var body: some View {
        NavigationLink {
            ProfileView(
                figure: figure
            )
        } label: {
            HStack(spacing: 20) {
                VStack(
                    alignment: .leading,
                    spacing: 10
                ) {
                    Text(result.label)
                        .font(.headline)
                        .foregroundStyle(
                            Color.primaryText
                        )

                    if let description =
                        result.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(
                                Color.secondaryText
                            )
                    }
                }

                Spacer()

                Image(
                    systemName: "chevron.right"
                )
                .font(
                    .system(
                        size: 13,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    Color.secondaryText
                )
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
            .padding()
            .background {
                RoundedRectangle(
                    cornerRadius: 12
                )
                .fill(Color.white)
            }
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
