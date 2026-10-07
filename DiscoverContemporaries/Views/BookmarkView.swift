import SwiftUI

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
                    FigureListRow(
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
        VStack(spacing: 16) {
            Image(systemName: "heart")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(Color.secondaryText)

            Text("Saved figures")
                .font(.headline)
                .foregroundStyle(Color.primaryText)

            Text("Your bookmarked profiles will appear here.")
                .font(.subheadline)
                .foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
        .padding(24)
    }

    // MARK: - Error State

    private func errorView(message: String) -> some View {
        ContentUnavailableView(
            "Unable to load saves",
            systemImage: "exclamationmark.triangle",
            description: Text(message)
        )
    }

    // MARK: - Actions

    private func removeFigures(at offsets: IndexSet) {
        let figuresToRemove = offsets.map {
            model.figures[$0]
        }

        for figure in figuresToRemove {
            Task {
                await model.remove(figure)
            }
        }
    }
}

// MARK: - Figure List Row

struct FigureListRow: View {
    let name: String
    let subtitle: String?
    let imageName: String?
    let imageURL: URL?

    var body: some View {
        HStack(spacing: 14) {
            PortraitImage(
                imageName: imageName,
                imageURL: imageURL
            )
            .frame(width: 60, height: 60)
            .clipShape(
                RoundedRectangle(cornerRadius: 5)
            )

            VStack(alignment: .leading, spacing: 5) {
                Text(name)
                    .font(.headline)
                    .foregroundStyle(Color.primaryText)
                    .lineLimit(2)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.secondaryText)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        BookmarkView()
    }
}
