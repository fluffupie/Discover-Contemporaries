import SwiftUI

struct FigureCard: View {
    let figure: HistoricalFigure
    let height: CGFloat

    var body: some View {
        ZStack(alignment: .bottomLeading) {

            AsyncImage(url: figure.imageURL) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Color.gray.opacity(0.12)
                        ProgressView()
                    }

                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()

                case .failure:
                    ZStack {
                        Color.gray.opacity(0.12)

                        Image(systemName: "person.crop.rectangle")
                            .font(.system(size: 32))
                            .foregroundStyle(.secondary)
                    }

                @unknown default:
                    EmptyView()
                }
            }
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

                if let region = figure.region {
                    Text(region)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.78))
                        .lineLimit(1)
                } else if let description = figure.description {
                    Text(description)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.78))
                        .lineLimit(1)
                }
            }
            .padding(8)
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.12))
        )
    }
}
