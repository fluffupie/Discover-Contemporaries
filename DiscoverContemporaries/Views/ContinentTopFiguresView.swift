import SwiftUI
import SwiftData

struct ContinentTopFiguresView: View {
    /// The continent whose historical figures are being displayed.
    let continent: Continent

    /// The view model responsible for loading and managing historical figures.
    @StateObject private var model = ContinentTopFiguresViewModel()

    /// The SwiftData model context used to initialise the cache repository.
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

            } else if model.figures.isEmpty {
                ContentUnavailableView(
                    "No figures found",
                    systemImage: "person.crop.circle.badge.questionmark"
                )

            } else {
                figuresList
            }
        }
        .background(Color.appBackground)
        .navigationTitle(continent.name)
        .navigationBarTitleDisplayMode(.inline)
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
        List(model.figures) { figure in
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
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.appBackground)
    }
}

#Preview {
    NavigationStack {
        ContinentTopFiguresView(
            continent: Continent(
                id: "Q46",
                name: "Europe",
                systemImage: "globe.europe.africa.fill"
            )
        )
    }
}
