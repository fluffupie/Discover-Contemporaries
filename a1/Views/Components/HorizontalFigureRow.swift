import SwiftUI

struct HorizontalFigureRow: View {
    let figure: HistoricalFigure

    var body: some View {
        HStack(spacing: 12) {
            PortraitImage(imageName: figure.imageName)
                .frame(width: 74, height: 74)
                .clipShape(RoundedRectangle(cornerRadius: 4))

            VStack(alignment: .leading, spacing: 5) {
                Text(figure.name)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.primaryText)
                    .lineLimit(1)
                Text(figure.era)
                    .font(.caption2)
                    .foregroundStyle(Color.secondaryText)
                Text(figure.summary)
                    .font(.caption2)
                    .foregroundStyle(Color.secondaryText)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(10)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}
