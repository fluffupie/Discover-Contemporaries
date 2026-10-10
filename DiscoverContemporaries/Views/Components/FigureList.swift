import SwiftUI

/// Displays a historical figure in a compact list row with a portrait, name, and optional subtitle.
struct FigureList: View {
    let name: String
    let subtitle: String?
    let imageName: String?
    let imageURL: URL?

    var body: some View {
        HStack(spacing: 14) {
            PortraitImage(
                imageName: imageName,
                imageURL: imageURL
            )
            .frame(width: 60, height: 60)
            .clipShape(
                RoundedRectangle(cornerRadius: 5)
            )

            VStack(alignment: .leading, spacing: 5) {
                Text(name)
                    .font(.headline)
                    .foregroundStyle(Color.black.opacity(0.85))
                    .lineLimit(2)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color.secondaryText)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }
}
