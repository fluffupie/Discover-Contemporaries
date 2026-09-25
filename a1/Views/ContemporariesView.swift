import SwiftUI

struct ContemporariesView: View {
    let figure: HistoricalFigure

    private let controller = FiguresController.shared

    private var contemporaryFigures: [HistoricalFigure] {
        controller.contemporaries(for: figure)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                Text(figure.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.primaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)

                if contemporaryFigures.isEmpty {
                    Text("No overlapping lifespans in the current data.")
                        .font(.caption)
                        .foregroundStyle(Color.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    ForEach(contemporaryFigures) { contemporary in
                        HorizontalFigureRow(figure: contemporary)
                    }
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 16)
            .padding(.bottom, 26)
        }
        .background(Color.appBackground)
        .h1NavigationTitle("Contemporaries")
    }
}
