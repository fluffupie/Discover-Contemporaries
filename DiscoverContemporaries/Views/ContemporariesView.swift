import SwiftUI
import Combine
import Foundation

struct ContemporariesView: View {
    let figure: HistoricalFigure

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
            model.load(for: figure)
        }
    }

    // MARK: - Contemporaries List

    private var contemporariesList: some View {
        List(model.figures) { contemporary in
            NavigationLink {
                ProfileView(
                    figure: contemporary.historicalFigure
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
