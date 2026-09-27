import SwiftData
import SwiftUI

struct HomeView: View {

    @Environment(\.modelContext) private var modelContext
    @StateObject private var model = FigureViewModel()
    @Query(sort: \CachedHistoricalFigure.name) private var cachedFigures:
        [CachedHistoricalFigure]

    private var isSearching: Bool {
        !model.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
    }

    private var defaultFigures: [HistoricalFigure] {
        cachedFigures.prefix(4).map { $0.toHistoricalFigure() }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                HeaderView()

                SearchField(searchText: $model.searchText).onSubmit {
                    model.searchFigures()
                }

                Text(isSearching ? "Search results" : "Explore figures")
                    .font(.h1Title)
                    .tracking(1.1)
                    .foregroundStyle(Color.primaryText)

                if isSearching {
                    if model.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 30)

                    } else if let errorMessage = model.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundStyle(Color.secondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 30)

                    } else if !model.searchResults.isEmpty {
                        VStack(spacing: 12) {
                            ForEach(model.searchResults) { result in
                                WikidataSearchResultRow(result: result)
                            }
                        }
                    }
                } else {
                    DefaultCachedFiguresGrid(figures: defaultFigures)
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
            do {
                try FigureDataSeeder.seedIfNeeded(context: modelContext)
            } catch {
                print("Failed to seed figures: \(error)")
            }
        }
    }
}

private struct DefaultCachedFiguresGrid: View {
    let figures: [HistoricalFigure]

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        if figures.isEmpty {
            EmptySearchView()
        } else {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(figures) { figure in
                    NavigationLink {
                        ProfileView(figure: figure)
                    } label: {
                        FigureCard(figure: figure)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct HeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            Text("Who lived at\nthe same time?")
                .font(.system(size: 30, weight: .semibold, design: .serif))
                .foregroundStyle(Color.primaryText)
                .lineSpacing(1)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.leading)

            Text("Explore history through overlapping lifespans.")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color.secondaryText)
                .padding(.top, 2)
        }
        .padding(.top, 6)
        .padding(.bottom, 4)
    }
}

private struct WikidataSearchResultRow: View {

    let result: WikidataSearchResult

    private var figure: HistoricalFigure {
        HistoricalFigure(
            id: result.id,
            name: result.label,
            descriptionText: result.description,
            gender: nil,
            birthDate: nil,
            deathDate: nil,
            country: nil,
            placeOfBirth: nil,
            occupations: [],
            movements: [],
            imageURL: nil,
            imageName: nil
        )
    }

    var body: some View {
        NavigationLink {
            ProfileView(figure: figure)
        } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(result.label)
                        .font(.headline)
                        .foregroundStyle(Color.primaryText)

                    if let description = result.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(Color.secondaryText)
                    }

//                    Text(result.id)
//                        .font(.caption)
//                        .foregroundStyle(Color.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.secondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
            )
        }
        .buttonStyle(.plain)
    }
}
