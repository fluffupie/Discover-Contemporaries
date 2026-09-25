import SwiftUI

struct FigureCard: View {
    let figure: HistoricalFigure
    let height: CGFloat

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            PortraitImage(imageName: figure.imageName)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .clipped()

            LinearGradient(
                colors: [.clear, .black.opacity(0.72)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(figure.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(figure.era)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.78))
                    .lineLimit(1)
            }
            .padding(8)
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(figure.accentColor.opacity(0.18))
        )
    }
}
