import SwiftUI
import SwiftData

struct ContinentTopFiguresView: View {
    let continent: Continent

    @StateObject private var model = ContinentTopFiguresViewModel()
    @Environment(\.modelContext)
    private var modelContext

    var body: some View {
        Group {
            if model.figures.isEmpty && model.isLoading {
                ProgressView("Loading…")

            } else if let errorMessage = model.errorMessage,
                      model.figures.isEmpty {
                ContentUnavailableView(
                    "Unable to load figures",
                    systemImage: "exclamationmark.triangle",
                    description: Text(errorMessage)
                )
            } else {
                figuresList
            }
        }
        .navigationTitle(continent.name)
        .task {
            let repository = FigureCacheRepository(
                context: modelContext
            )

            model.load(
                for: continent,
                repository: repository
            )
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
