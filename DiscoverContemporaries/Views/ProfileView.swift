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
        figure.occupations.first ?? "Historical figure"
    }

    private var countryText: String {
        figure.country ?? "Unknown country"
    }

    private var birthplaceText: String {
        figure.placeOfBirth ?? "Unknown birthplace"
    }

    private var movementsText: String {
        figure.movements.isEmpty ? "No movement listed" : figure.movements.joined(separator: ", ")
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
            VStack(alignment: .leading, spacing: 18) {
                ProfileHero(
                    figure: figure,
                    imageName: profileImageName,
                    imageURL: profileImageURL,
                    roleLabel: roleLabel,
                    countryText: countryText
                )

                ProfileSection(title: "Summary") {
                    Text(figure.descriptionText ?? "No description available yet.")
                        .font(.system(.body, design: .serif))
                        .foregroundStyle(Color.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                ProfileSection(title: "Details") {
                    VStack(spacing: 10) {
                        FactRow(icon: "calendar", label: "Lifespan", value: figure.lifespan)
                        FactRow(icon: "hourglass", label: "Age", value: figure.ageText)
                        FactRow(icon: "mappin.and.ellipse", label: "Birthplace", value: birthplaceText)
                        FactRow(icon: "globe", label: "Country", value: countryText)
                        FactRow(icon: "sparkles", label: "Movement", value: movementsText)
                    }
                }

                ProfileSection(title: "Contemporaries") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Contemporaries discovery is not implemented for Wikidata figures yet.")
                            .font(.caption)
                            .foregroundStyle(Color.secondaryText)

                        NavigationLink {
                            ContemporariesView(figure: figure)
                        } label: {
                            Label("See all", systemImage: "person.2.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.tealButton)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
        .background(Color.appBackground)
        .task {
            loadPortraitImage()
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ProfileHero: View {
    let figure: HistoricalFigure
    let imageName: String?
    let imageURL: URL?
    let roleLabel: String
    let countryText: String

    var body: some View {
        VStack(spacing: 14) {
            PortraitImage(imageName: imageName, imageURL: imageURL)
                .frame(width: 154, height: 154)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.85), lineWidth: 3)
                )
                .shadow(color: .black.opacity(0.16), radius: 12, y: 7)

            VStack(spacing: 8) {
                Text(figure.name)
                    .font(.system(size: 28, weight: .semibold, design: .serif))
                    .foregroundStyle(Color.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)

                HStack(spacing: 8) {
                    ProfilePill(text: roleLabel, systemImage: "sparkle")
                    ProfilePill(text: countryText, systemImage: "globe")
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 14)
        .background(Color.white.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }
}

private struct ProfilePill: View {
    let text: String
    let systemImage: String

    var body: some View {
        Label(text.uppercased(), systemImage: systemImage)
            .font(Font.custom("AlegreyaSansSC-Regular", size: 13).weight(.medium))
            .foregroundStyle(Color.ochre)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.ochre.opacity(0.08))
            .clipShape(Capsule())
    }
}

private struct ProfileSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Color.primaryText)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.white.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }
}

private struct FactRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.tealButton)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(Color.secondaryText)

                Text(value)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
    }
}
