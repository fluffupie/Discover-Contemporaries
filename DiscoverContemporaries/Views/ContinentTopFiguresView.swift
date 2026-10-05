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

    private var figuresList: some View {
        List(model.figures) { figure in
            NavigationLink {
                ProfileView(figure: figure)
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(figure.name)
                        .font(.headline)

                    Text(figure.lifespan)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

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
