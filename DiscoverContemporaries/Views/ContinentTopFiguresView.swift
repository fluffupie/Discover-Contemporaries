import SwiftUI
import SwiftData

struct ContinentTopFiguresView: View {
    /// The continent whose historical figures are being displayed.
    let continent: Continent

    @StateObject private var model = SeededFiguresViewModel()

    /// The SwiftData model context used to initialise the cache repository.
    @Environment(\.modelContext)
    private var modelContext

    var body: some View {
        Group {
            if model.figures.isEmpty && model.isLoading {
                ProgressView("Loading…")
                    .accessibilityHint("Please wait while figures are loading.")

            } else if let errorMessage = model.errorMessage,
                      model.figures.isEmpty {

                ContentUnavailableView(
                    "Unable to load figures",
                    systemImage: "exclamationmark.triangle",
                    description: Text(errorMessage)
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Unable to load figures")
                .accessibilityValue(errorMessage)
                .accessibilityHint("Try again later or pull to refresh if available.")

            } else if model.figures.isEmpty {
                ContentUnavailableView(
                    "No figures found",
                    systemImage: "person.crop.circle.badge.questionmark"
                )
                .accessibilityElement(children: .combine)
                .accessibilityLabel("No figures found")
                .accessibilityHint("No matching historical figures were found for this continent.")

            } else {
                figuresList
            }
        }
        .background(Color.appBackground)
        .navigationTitle(continent.name)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: continent.id) {
            let repository = FigureCacheRepository(context: modelContext)
            await model.load(
                key: continent.id,
                seededIDs: ContinentFigureIDs.ids(for: continent.id),
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
                .accessibilityElement(children: .combine)
                .accessibilityLabel(figure.name)
                .accessibilityValue(figure.descriptionText ?? figure.name)
                .accessibilityHint("Opens profile")
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

