import SwiftUI

/// Displays a historical figure as a portrait card with their name and birthplace.
struct FigureCard: View {

    /// The historical figure represented by the card.
    let figure: HistoricalFigure

    /// The portrait and biographical information displayed on the card.
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
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(figure.name)
                    .font(.subheadline.weight(.medium))
                    .fontDesign(.serif)
                    .foregroundStyle(Color.primaryText)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )

                Text(figure.birthPlace ?? "Unknown birth place")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.secondaryText)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "\(figure.name). \(figure.birthPlace ?? "Unknown birth place")."
        )
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 10)
        )
        .shadow(
            color: .black.opacity(0.08),
            radius: 8,
            y: 4
        )
    }
}

#Preview {
    func date(
        _ year: Int,
        _ month: Int = 1,
        _ day: Int = 1
    ) -> Date {
        Calendar(identifier: .gregorian)
            .date(
                from: DateComponents(
                    year: year,
                    month: month,
                    day: day
                )
            )!
    }

    let sample = HistoricalFigure(
        id: "Q5592",
        name: "Marie Curie",
        descriptionText: "Physicist and chemist",
        gender: "female",
        birthPlace: "Warsaw, Poland",
        birthDate: date(1867, 11, 7),
        deathDate: date(1934, 7, 4),
        occupations: ["Physicist", "Chemist"],
        movements: [],
        imageURL: nil,
        imageName: nil
    )

    return VStack(spacing: 16) {
        FigureCard(figure: sample)
            .frame(width: 180)
            .padding()
            .background(Color.appBackground)
    }
}
