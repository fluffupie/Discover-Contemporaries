import SwiftUI

struct FeatureCard: View {

    let figure: HistoricalFigure

    private var gradient: LinearGradient {
        LinearGradient(
            colors: [
                .black.opacity(0.8),
                .black.opacity(0.0)
            ],
            startPoint: .bottom,
            endPoint: .center
        )
    }

    var body: some View {
        GeometryReader { geometry in
            PortraitImage(
                imageName: figure.imageName,
                imageURL: figure.imageURL
            )
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
            .clipped()
            .overlay {
                ZStack(alignment: .bottomLeading) {
                    gradient

                    VStack(alignment: .leading, spacing: 6) {
                        Text(figure.name)
                            .font(.title2)
                            .bold()

                        Text(figure.lifespan)
                            .font(.subheadline)

                        Text(
                            figure.subtitle
                                ?? figure.primaryOccupation
                        )
                        .font(.caption)
                        .lineLimit(2)
                    }
                    .foregroundStyle(.white)
                    .padding(16)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(figure.name)
        .accessibilityHint("Opens historical figure profile")
    }
}
