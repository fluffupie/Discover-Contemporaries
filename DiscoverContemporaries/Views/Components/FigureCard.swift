import SwiftUI

struct FigureCard: View {
    let figure: HistoricalFigure

    private var countryText: String {
        figure.country ?? "Unknown country"
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let textHeight = width / 3

            VStack(alignment: .leading, spacing: 0) {
                PortraitImage(imageName: figure.imageName, imageURL: figure.imageURL)
                    .frame(width: width, height: width)
                    .clipped()

                VStack(alignment: .leading, spacing: 4) {
                    Text(figure.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(countryText)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(Color.secondaryText)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 9)
                .frame(width: width, height: textHeight, alignment: .topLeading)
                .background(Color.white)
            }
            .frame(width: width, height: width + textHeight)
        }
        .aspectRatio(3 / 4, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.12))
        )
    }
}
