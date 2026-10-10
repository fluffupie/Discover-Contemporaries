import SwiftData
import SwiftUI

/// Displays a searchable list of historical figures that can be selected for comparison.
struct CompareSearchView: View {

    /// The historical figure that will be compared with the selected search result.
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
                SearchField(searchText: $model.searchText)
                    .accessibilityLabel("Search figures to compare")
                    .accessibilityHint("Type a name and press Return to search")
                    .onSubmit {model.performSearch()}
                    .onChange(of: model.searchText) { model.searchTextChanged()}

                if model.isLoading {
                    ProgressView("Searching…")
                        .accessibilityHint("Please wait while results are loading")
                        .frame(maxWidth: .infinity)
                }

                if let errorMessage = model.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Search error")
                        .accessibilityValue(errorMessage)
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
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel(result.label)
                            .accessibilityHint("Select to compare with \(firstFigure.name)")
                            .accessibilityValue(result.description ?? "No description")
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
