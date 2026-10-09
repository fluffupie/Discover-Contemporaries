import SwiftData
import SwiftUI

struct CompareSearchView: View {
    let firstFigure: HistoricalFigure

    @Environment(\.modelContext)
    private var modelContext

    @StateObject
    private var model = ComparisonViewModel()

    @State
    private var selectedFigure: HistoricalFigure?

    var body: some View {
        List {
            Section {
                SearchField(
                    searchText: $model.searchText
                )
                .onSubmit {
                    model.performSearch()
                }
                .onChange(of: model.searchText) {
                    model.searchTextChanged()
                }

                if model.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }

                if let errorMessage = model.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !model.results.isEmpty {
                Section("Search results") {
                    ForEach(model.results) { result in
                        Button {
                            select(result)
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
            }
        }
        .navigationTitle("Search to Compare")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(
            item: $selectedFigure
        ) { figure in
            ComparisonView(
                firstFigure: firstFigure,
                secondFigure: figure
            )
        }
    }

    private func select(
        _ result: WikidataSearchResult
    ) {
        let repository = FigureCacheRepository(
            context: modelContext
        )

        model.resolveFigure(
            from: result,
            repository: repository
        ) { figure in
            selectedFigure = figure
        }
    }
}
