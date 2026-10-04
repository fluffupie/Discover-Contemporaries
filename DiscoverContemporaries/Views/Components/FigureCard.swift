import SwiftUI

struct FigureCard: View {
    let figure: HistoricalFigure

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PortraitImage(
                imageName: figure.imageName,
                imageURL: figure.imageURL
            )
            .aspectRatio(1, contentMode: .fill)
            .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text(figure.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(figure.birthPlace ?? "Unknown birth place")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.secondaryText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(Color.white)
        }
        .aspectRatio(3 / 4, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.12))
        )
    }
}
