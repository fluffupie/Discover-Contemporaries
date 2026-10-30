import SwiftUI

/// Displays the user's bookmarked historical figures and supports removing saved entries.
struct BookmarkView: View {
    @StateObject private var model = BookmarkViewModel()

    var body: some View {
        Group {
            if model.isLoading {
                ProgressView("Loading saved figures…")
                    .accessibilityHint("Please wait while saved figures are loaded.")

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
        .toolbar {
            #if DEBUG
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    CachedFiguresDebugView()
                } label: {
                    Image(systemName: "tray.full")
                }
            }
            #endif
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
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(figure.name)
                    .accessibilityHint("Opens profile")
                    .accessibilityValue(figure.descriptionText ?? figure.name)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button(role: .destructive) {
                        Task { await model.remove(figure) }
                    } label: {
                        Label("Remove from saves", systemImage: "trash")
                    }
                }
                .accessibilityAction(named: "Remove from saves") {
                    Task { await model.remove(figure) }
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
            description: Text("Your bookmarked profiles will appear here.")
                .foregroundStyle(Color.black.opacity(0.75))
        )
        .accessibilityElement(children: .combine)
        .accessibilityHint("Bookmark a profile to see it listed here.")
    }

    // MARK: - Error State

    private func errorView(message: String) -> some View {
        ContentUnavailableView(
            "Unable to load saves",
            systemImage: "exclamationmark.triangle",
            description: Text(message)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Unable to load saves")
        .accessibilityHint("Try again later or pull to refresh.")
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
