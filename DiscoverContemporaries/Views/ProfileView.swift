import SwiftData
import SwiftUI

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext

    let figure: HistoricalFigure

    @State private var resolvedImageName: String?
    @State private var resolvedImageURL: URL?

    private var profileImageName: String? {
        resolvedImageName ?? figure.imageName
    }

    private var profileImageURL: URL? {
        resolvedImageURL ?? figure.imageURL
    }

    private var roleLabel: String {
        figure.occupations.first ?? figure.country ?? "Historical figure"
    }

    private func loadPortraitImage() {
        guard profileImageName == nil, profileImageURL == nil else {
            return
        }

        let repository = FigureCacheRepository(context: modelContext)

        if let cachedFigure = try? repository.fetchFigure(withID: figure.id) {
            resolvedImageName = cachedFigure.imageName
            resolvedImageURL = cachedFigure.imageURL

            if resolvedImageName != nil || resolvedImageURL != nil {
                return
            }
        }

        WikidataAPI.fetchPortraitURL(forID: figure.id) { imageURL in
            resolvedImageURL = imageURL
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                PortraitImage(imageName: profileImageName, imageURL: profileImageURL)
                    .frame(width: 150, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: .black.opacity(0.18), radius: 12, y: 7)
                    .padding(.top, 10)

                VStack(alignment: .leading, spacing: 6) {
                    FigureIdentityBanner(figure: figure)

                    Text(figure.descriptionText ?? "No description available yet.")
                        .font(.system(.body, design: .serif))
                        .foregroundColor(.black)

                    HStack {
                        Text(figure.lifespan)
                            .font(Font.custom("AlegreyaSansSC-Regular", size: 16))
                            .foregroundColor(.black)
                        Ellipse()
                            .foregroundColor(.clear)
                            .frame(width: 5, height: 5)
                            .background(Color(red: 0.62, green: 0.11, blue: 0.14))
                        Text(figure.ageText)
                            .font(Font.custom("AlegreyaSansSC-Regular", size: 16))
                            .foregroundColor(.black)
                    }

                    RolePill(label: roleLabel)
                        .frame(maxWidth: .infinity, alignment: .center)

                    Text("Contemporaries")
                        .font(.headline)
                        .foregroundColor(.emerald)
                }

                // TODO: Populate this from Wikidata lifespan data once contemporaries discovery is implemented.
                Text("Contemporaries discovery is not implemented for Wikidata figures yet.")
                    .font(.caption)
                    .foregroundStyle(Color.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                NavigationLink {
                    ContemporariesView(figure: figure)
                } label: {
                    Text("See all")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.tealButton)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 30)
        }
        .background(Color.appBackground)
        .task {
            loadPortraitImage()
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct FigureIdentityBanner: View {
    let figure: HistoricalFigure

    var body: some View {
        HStack(spacing: 12) {
            Rectangle()
                .fill(Color.ochre)
                .frame(width: 3)
                .clipShape(Capsule())

            VStack(alignment: .leading, spacing: 3) {
                Text(figure.name.uppercased())
                    .font(.system(size: 20, weight: .regular, design: .serif))
                    .tracking(1.2)
                    .foregroundStyle(Color.primaryText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                    .multilineTextAlignment(.leading)

                if let country = figure.country {
                    Text(country)
                        .font(.caption)
                        .foregroundStyle(Color.secondaryText)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
        .background(Color.white.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.ochre.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
    }
}

private struct RolePill: View {
    let label: String

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "sparkle")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.ochre.opacity(0.78))

            Text(label.uppercased())
                .font(Font.custom("AlegreyaSansSC-Regular", size: 15).weight(.medium))
                .tracking(1.1)
                .foregroundStyle(Color.ochre)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.62))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color.ochre.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.035), radius: 5, x: 0, y: 2)
        .accessibilityElement(children: .combine)
    }
}
