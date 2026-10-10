import SwiftUI

struct EmptySearchView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.title.weight(.semibold))
                .foregroundStyle(Color.secondaryText)

            Text("No matching figures")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Color.black.opacity(0.85))

            Text("Try searching by name, role, era, or lifespan.")
                .font(.caption2)
                .foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}

struct CompareCard: View {
    let figure: HistoricalFigure

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PortraitImage(imageURL: figure.imageURL)
                .scaledToFill()
                .frame(height: 135)
                .frame(maxWidth: .infinity)
                .clipped()

            VStack(alignment: .leading, spacing: 5) {
                Text(figure.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.black.opacity(0.85))
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                Text(figure.lifespan)
                    .font(.caption2)
                    .foregroundStyle(Color.secondaryText)
                Text(figure.ageText)

                    .font(.caption2.weight(.regular))

            }
            .padding(10)
        }
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }
}
#Preview("Empty Search View") {
    VStack(spacing: 20) {
        EmptySearchView()
            .padding()
            .background(Color.appBackground)
    }
    .padding()
}

#Preview("Compare Card") {
    // Helper to construct a date from year, month, day
    func date(_ year: Int, _ month: Int = 1, _ day: Int = 1) -> Date {
        Calendar(identifier: .gregorian)
            .date(from: DateComponents(year: year, month: month, day: day))!
    }

    // Sample historical figure for the compare card
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
        CompareCard(figure: sample)
            .frame(width: 180)
            .padding()
            .background(Color.appBackground)
    }
}

