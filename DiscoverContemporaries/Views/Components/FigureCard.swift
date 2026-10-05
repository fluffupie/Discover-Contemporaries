import SwiftUI

struct FigureCard: View {
    let figure: HistoricalFigure

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PortraitImage(
                imageName: figure.imageName,
                imageURL: figure.imageURL
            )
            .scaledToFill()
            .frame(height: 160)
            .frame(maxWidth: .infinity)
            .clipped()

            VStack(alignment: .leading, spacing: 6) {
                Text(figure.name)
                    .font(.system(size: 16, weight: .medium, design: .serif))
                    .foregroundStyle(Color.primaryText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)

                Text(figure.birthPlace ?? "Unknown birth place")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.secondaryText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(figure.name). \(figure.birthPlace ?? "Unknown birth place").")
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }
}
