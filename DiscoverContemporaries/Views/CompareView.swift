import SwiftUI

struct CompareView: View {
    private let controller = FiguresController.shared

    var body: some View {
        let firstFigure = controller.figures.first ?? .placeholder
        let secondFigure = controller.figures.dropFirst(3).first ?? controller.figures.dropFirst().first ?? firstFigure

        VStack(spacing: 16) {
            VStack(spacing: 12) {
                CompareCard(figure: firstFigure, tint: .rosePanel)
                CompareCard(figure: secondFigure, tint: .mintPanel)

                Text("They share a strong relationship to public change and leadership.")
                    .font(.caption)
                    .foregroundStyle(Color.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, 12)
            }
            .padding(16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .background(Color.appBackground)
        .h1NavigationTitle("Compare")
    }
}
