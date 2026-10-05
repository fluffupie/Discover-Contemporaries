import SwiftUI

struct SearchAndCompareView: View {
    let firstFigure: HistoricalFigure

    @StateObject private var model = ComparisonViewModel()

    var body: some View {
        List {
            Section(footer: footerText) {
                VStack(alignment: .leading, spacing: 10) {
                    SearchField(searchText: $model.searchText)
                        .onSubmit {
                            model.performSearch()
                        }
                        .onChange(of: model.searchText) {
                            model.searchTextChanged()
                        }

                    searchButton

                    if model.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else if let errorMessage = model.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if !model.results.isEmpty {
                Section("Search results") {
                    ForEach(model.results) { result in
                        NavigationLink {
                            LifespanCompareView(
                                firstFigure: firstFigure,
                                secondFigure: HistoricalFigure(
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
                            )
                        } label: {
                            SearchResultRow(result: result)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Search to Compare")
    }

    private var footerText: some View {
        Text("Search any figure to compare with \(firstFigure.name).")
            .font(.footnote)
            .foregroundStyle(.secondary)
    }

    private var searchButton: some View {
        Button {
            model.performSearch()
        } label: {
            Label("Search", systemImage: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.tealButton)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
    }
}

private struct SearchResultRow: View {
    let result: WikidataSearchResult

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(result.label)
                .font(.headline)

            if let description = result.description {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
