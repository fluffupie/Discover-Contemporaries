import SwiftUI

struct EmptySearchView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(Color.secondaryText)

            Text("No matching figures")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.primaryText)

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
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.primaryText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.9)
                Text(figure.lifespan)
                    .font(.caption2)
                    .foregroundStyle(Color.secondaryText)
                Text(figure.ageText)
                    .font(.system(size: 12, weight: .regular))

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
