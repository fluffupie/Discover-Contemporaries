import SwiftUI
import SwiftData

struct ContemporariesView: View {
    /// The SwiftData model context used to initialise the cache repository.
    @Environment(\.modelContext)
    private var modelContext
    
    /// The historical figure whose contemporaries are being displayed.
    let figure: HistoricalFigure

    /// The view model responsible for loading and managing contemporaries.
    @StateObject private var model = ContemporariesViewModel()

    var body: some View {
        Group {
            if model.isLoading {
                ProgressView("Loading…")
                    .accessibilityHint("Please wait while contemporaries are loading.")

            } else if let errorMessage = model.errorMessage {
                errorView(message: errorMessage)

            } else if model.figures.isEmpty {
                ContentUnavailableView(
                    "No contemporaries",
                    systemImage: "person.2"
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel("No contemporaries found")
                .accessibilityHint("No overlapping lifespans were found for this figure.")

            } else {
                contemporariesList
            }
        }
        .background(Color.appBackground)
        .navigationTitle("Contemporaries")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: figure.id) {
            let repository = FigureCacheRepository(context: modelContext)
            await model.load(for: figure, repository: repository)
        }
    }

    // MARK: - Contemporaries List

    private var contemporariesList: some View {
        List(model.figures) { contemporary in
            NavigationLink {
                ComparisonView(
                    firstFigure: figure,
                    secondFigure: contemporary.historicalFigure
                )
            } label: {
                FigureList(
                    name: contemporary.name,
                    subtitle: contemporary.lifespanText,
                    imageName: nil,
                    imageURL: contemporary.imageURL
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel(contemporary.name)
                .accessibilityValue(contemporary.lifespanText)
                .accessibilityHint("Opens comparison with \(figure.name)")
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
    }

    // MARK: - Error State
    private func errorView(message: String) -> some View {
        ContentUnavailableView {
            Label("Unable to load contemporaries", systemImage: "exclamationmark.triangle.fill")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again") {
                Task {
                    let repository = FigureCacheRepository(context: modelContext)
                    await model.load(for: figure, repository: repository)
                }
            }
        }
    }
}
