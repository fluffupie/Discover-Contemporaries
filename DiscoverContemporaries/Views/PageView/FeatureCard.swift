import SwiftUI

struct FeatureCard: View {

    let figure: HistoricalFigure
    
    @Environment(\.dynamicTypeSize)
    private var dynamicTypeSize

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

                    VStack(alignment: .leading, spacing: 4) {
                        Text(figure.name)
                            .font(.title2)
                            .bold()
                            .lineLimit(2)

                        Text(figure.lifespan)
                            .font(.subheadline)

                        if !dynamicTypeSize.isAccessibilitySize {
                            Text(figure.subtitle ?? figure.primaryOccupation)
                                .font(.caption)
                                .lineLimit(2)
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 34)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.6))
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(figure.name)
        .accessibilityHint("Opens historical figure profile")
    }
}
