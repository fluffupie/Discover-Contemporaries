import SwiftUI

/// Displays the user's bookmarked historical figures and supports removing saved entries.
struct BookmarkView: View {
    @StateObject private var model = BookmarkViewModel()

    var body: some View {
        Group {
            if model.isLoading {
                ProgressView("Loading saved figures…")

            } else if let errorMessage = model.errorMessage {
                errorView(message: errorMessage)

            } else if model.figures.isEmpty {
                emptyState

            } else {
                savedFiguresList
            }
        }
        .background(Color.appBackground)
        .navigationTitle("Saves")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await model.load()
        }
        .refreshable {
            await model.refresh()
        }
    }

    // MARK: - Saved Figures List

    private var savedFiguresList: some View {
        List {
            ForEach(model.figures) { figure in
                NavigationLink {
                    ProfileView(
                        figure: figure.historicalFigure
                    )
                } label: {
                    FigureList(
                        name: figure.name,
                        subtitle: figure.descriptionText,
                        imageName: figure.imageName,
                        imageURL: figure.imageURL
                    )
                }
            }
            .onDelete { offsets in
                removeFigures(at: offsets)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView(
            "No saved figures",
            systemImage: "heart",
            description: Text(
                "Your bookmarked profiles will appear here."
            )
        )
    }

    // MARK: - Error State

    private func errorView(
        message: String
    ) -> some View {
        ContentUnavailableView(
            "Unable to load saves",
            systemImage: "exclamationmark.triangle",
            description: Text(message)
        )
    }

    // MARK: - Actions

    private func removeFigures(
        at offsets: IndexSet
    ) {
        let figuresToRemove = offsets.map {
            model.figures[$0]
        }

        Task {
            for figure in figuresToRemove {
                await model.remove(figure)
            }
        }
    }
}
