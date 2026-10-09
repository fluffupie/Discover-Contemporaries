import SwiftUI
import Combine
import Foundation
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

            } else if let errorMessage = model.errorMessage {
                errorView(message: errorMessage)

            } else if model.figures.isEmpty {
                ContentUnavailableView(
                    "No contemporaries",
                    systemImage: "person.2"
                )

            } else {
                contemporariesList
            }
        }
        .background(Color.appBackground)
        .navigationTitle("Contemporaries")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            let repository = FigureCacheRepository(
                context: modelContext
            )

            model.load(
                for: figure,
                repository: repository
            )
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
                .foregroundStyle(Color.secondaryText)
        }
        .padding()
    }
}
