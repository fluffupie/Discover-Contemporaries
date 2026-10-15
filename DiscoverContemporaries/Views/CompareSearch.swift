import SwiftData
import SwiftUI

/// Displays a searchable list of figures that can be selected for comparison.
struct CompareSearchView: View {
    /// The figure that will be compared with the selected search result.
    let firstFigure: HistoricalFigure

    @Environment(\.modelContext)
    private var modelContext

    @StateObject
    private var model = ComparisonViewModel()

    @State
    private var selectedFigure: HistoricalFigure?

    /// `true` while a tapped result is being resolved.
    @State
    private var isResolving = false

    @State
    private var alertMessage: String?

    var body: some View {
        List {
            Section {
                SearchField(searchText: $model.searchText)
                    .accessibilityLabel("Search figures to compare")
                    .accessibilityHint("Type a name and press Return to search")
                    .onSubmit { model.performSearch() }
                    .onChange(of: model.searchText) { model.searchTextChanged() }

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
                        .disabled(isResolving)
                    }
                }
                .opacity(isResolving ? 0.5 : 1)
            }
        }
        .navigationTitle("Search to Compare")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedFigure) { figure in
            ComparisonView(
                firstFigure: firstFigure,
                secondFigure: figure
            )
        }
        .alert(
            "Couldn't load figure",
            isPresented: Binding(
                get: { alertMessage != nil },
                set: { if !$0 { alertMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private func select(_ result: WikidataSearchResult) {
        guard !isResolving else { return }
        isResolving = true

        let repository = FigureCacheRepository(context: modelContext)

        Task {
            defer { isResolving = false }

            do {
                if let figure = try await model.resolveFigure(
                    from: result,
                    repository: repository
                ) {
                    selectedFigure = figure
                } else {
                    alertMessage = "That figure couldn't be found on Wikidata."
                }
            } catch is CancellationError {
                // The view went away. Not an error.
            } catch let error as URLError where error.code == .cancelled {
                // Same, surfaced by URLSession.
            } catch {
                alertMessage = error.localizedDescription
            }
        }
    }
}
