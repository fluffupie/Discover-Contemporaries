import SwiftUI

struct ContemporariesView: View {

    let figure: HistoricalFigure

    @StateObject
    private var model =
        ContemporariesViewModel()

    var body: some View {
        Group {
            if model.isLoading {
                ProgressView()

            } else if let error =
                model.errorMessage {
                Text(error)

            } else {
                List(model.figures) { contemporary in
                    NavigationLink {
                        ProfileView(
                            figure: contemporary.historicalFigure
                        )
                    } label: {
                        VStack(
                            alignment: .leading,
                            spacing: 4
                        ) {
                            Text(contemporary.name)
                                .font(.headline)

                            Text(
                                lifespanText(
                                    for: contemporary
                                )
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(
            "Contemporaries"
        )
        .task {
            model.load(
                for: figure
            )
        }
    }

    private func lifespanText(
        for figure: ContemporaryFigure
    ) -> String {
        guard
            let birth = figure.birthDate
        else {
            return "Unknown"
        }

        let formatter =
            HistoricalFigure
                .displayDateFormatter

        let birthText =
            formatter.string(from: birth)

        guard
            let death = figure.deathDate
        else {
            return "\(birthText) - Present"
        }

        return """
        \(birthText) - \(formatter.string(from: death))
        """
    }
}
