import SwiftUI

struct ContemporariesView: View {
    let figure: HistoricalFigure

    @StateObject private var model = ContemporariesViewModel()

    var body: some View {
        Group {
            if model.isLoading {
                ProgressView()

            } else if let errorMessage = model.errorMessage {
                Text(errorMessage)

            } else {
                List {
                    Section {
                        ForEach(model.figures) { contemporary in
                            NavigationLink {
                                ProfileView(
                                    figure: contemporary.historicalFigure
                                )
                            } label: {
                                ContemporaryRow(
                                    contemporary: contemporary
                                )
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Contemporaries")
        .task {
            model.load(for: figure)
        }
    }
}

// MARK: - Contemporary Row

private struct ContemporaryRow: View {
    let contemporary: ContemporaryFigure

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(contemporary.name)
                .font(.headline)

            Text(contemporary.lifespanText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
