import SwiftUI

struct ContinentTopFiguresView: View {
    let continent: Continent

    @StateObject private var model = ContinentTopFiguresViewModel()

    var body: some View {
        Group {
            if model.isLoading {
                ProgressView("Loading…")

            } else if let errorMessage = model.errorMessage {
                errorView(message: errorMessage)

            } else if model.figures.isEmpty {
                ContentUnavailableView(
                    "No results",
                    systemImage: "person.fill.questionmark"
                )

            } else {
                figuresList
            }
        }
        .navigationTitle(continent.name)
        .task {
            model.load(for: continent)
        }
    }

    // MARK: - Figures List

    private var figuresList: some View {
        List {
            ForEach(model.figures) { figure in
                NavigationLink {
                    ProfileView(
                        figure: figure
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
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
    }

    // MARK: - Error State

    private func errorView(message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
                .imageScale(.large)

            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    NavigationStack {
        ContinentTopFiguresView(
            continent: Continent(
                id: "Q46",
                name: "Europe"
            )
        )
    }
}
