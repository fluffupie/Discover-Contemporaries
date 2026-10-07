import SwiftUI

struct LifespanCompareView: View {
    let firstFigure: HistoricalFigure
    let secondFigure: HistoricalFigure

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Compare Lifespans")
                    .font(.headline)
                    .foregroundStyle(Color.primaryText)

                CompareCard(figure: firstFigure, tint: Color.white)
                CompareCard(figure: secondFigure, tint: Color.white)

                // Simple textual comparison fallback
                VStack(alignment: .leading, spacing: 8) {
                    Text("Summary")
                        .font(.subheadline)
                        .foregroundStyle(Color.primaryText)

                    Text("\(firstFigure.name) lived \(firstFigure.lifespan)")
                        .font(.caption)
                        .foregroundStyle(Color.secondaryText)

                    Text("\(secondFigure.name) lived \(secondFigure.lifespan)")
                        .font(.caption)
                        .foregroundStyle(Color.secondaryText)
                }
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(20)
        }
        .background(Color.appBackground)
        .navigationTitle("Compare")
        .navigationBarTitleDisplayMode(.inline)
    }
}
