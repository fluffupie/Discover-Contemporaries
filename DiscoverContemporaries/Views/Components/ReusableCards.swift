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

struct CategoryTile: View {
    let title: String
    let systemImage: String
    let color: Color

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 25, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 62, height: 62)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color.primaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

struct CategoryListRow: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.tealButton)
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
    }
}

struct MigrationPlaceholderRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        CategoryListRow(icon: icon, title: title)
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
