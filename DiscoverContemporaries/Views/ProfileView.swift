import SwiftData
import SwiftUI

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext

    let figure: HistoricalFigure

    @State private var resolvedImageName: String?
    @State private var resolvedImageURL: URL?
    
    @State private var resolvedCountry: String?
    @State private var resolvedBirthDate: Date?
    @State private var resolvedDeathDate: Date?

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
        resolvedCountry ?? figure.country ?? "Unknown country"
    }

    private var birthplaceText: String {
        figure.placeOfBirth ?? "Unknown birthplace"
    }

    private var movementsText: String {
        figure.movements.isEmpty ? "No movement listed" : figure.movements.joined(separator: ", ")
    }

    private var resolvedLifespanText: String {
        let birth = resolvedBirthDate ?? figure.birthDate
        let death = resolvedDeathDate ?? figure.deathDate
        guard let birth else { return "Unknown" }
        let birthText = HistoricalFigure.displayDateFormatter.string(from: birth)
        guard let death else { return "\(birthText) - Present" }
        let deathText = HistoricalFigure.displayDateFormatter.string(from: death)
        return "\(birthText) - \(deathText)"
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
    
    private func loadCountry() {
        // If we already have a country displayed, no work needed
        if resolvedCountry != nil || figure.country != nil {
            return
        }

        let repository = FigureCacheRepository(context: modelContext)

        // Try cache first
        if let cachedFigure = try? repository.fetchFigure(withID: figure.id),
           let cachedCountry = cachedFigure.country {
            resolvedCountry = cachedCountry
            return
        }

        // Fetch from network and persist
        WikidataAPI.fetchCountryName(for: figure) { country in
            guard let country else { return }

            // Update UI immediately
            resolvedCountry = country

            // Persist enriched figure
            let updated = HistoricalFigure(
                id: figure.id,
                name: figure.name,
                descriptionText: figure.descriptionText,
                gender: figure.gender,
                birthDate: figure.birthDate,
                deathDate: figure.deathDate,
                country: country,
                placeOfBirth: figure.placeOfBirth,
                occupations: figure.occupations,
                movements: figure.movements,
                imageURL: figure.imageURL,
                imageName: figure.imageName
            )

            do {
                try repository.save(updated)
            } catch {
                print("Failed to cache updated figure with country: \(error)")
            }
        }
    }

    private func loadLifespan() {
        // If already have dates resolved or present on figure, no work needed
        if (resolvedBirthDate != nil || figure.birthDate != nil) &&
            (resolvedDeathDate != nil || figure.deathDate != nil) {
            return
        }

        let repository = FigureCacheRepository(context: modelContext)

        // Try cache first
        if let cached = try? repository.fetchFigure(withID: figure.id) {
            if let b = cached.birthDate { resolvedBirthDate = b }
            if let d = cached.deathDate { resolvedDeathDate = d }
            if resolvedBirthDate != nil || resolvedDeathDate != nil { return }
        }

        // Fetch from network
        WikidataAPI.fetchLifespan(forID: figure.id) { birth, death in
            // Update UI immediately
            if resolvedBirthDate == nil { resolvedBirthDate = birth }
            if resolvedDeathDate == nil { resolvedDeathDate = death }

            // Persist enriched figure
            let updated = HistoricalFigure(
                id: figure.id,
                name: figure.name,
                descriptionText: figure.descriptionText,
                gender: figure.gender,
                birthDate: birth ?? figure.birthDate,
                deathDate: death ?? figure.deathDate,
                country: resolvedCountry ?? figure.country,
                placeOfBirth: figure.placeOfBirth,
                occupations: figure.occupations,
                movements: figure.movements,
                imageURL: figure.imageURL,
                imageName: figure.imageName
            )

            do {
                try repository.save(updated)
            } catch {
                print("Failed to cache updated figure lifespan: \(error)")
            }
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
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
                        .fixedSize(horizontal: false, vertical: true)
                }

                ProfileSection(title: "Details") {
                    VStack(spacing: 10) {
                        FactRow(icon: "calendar", label: "Lifespan", value: resolvedLifespanText)
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
            .padding(.top, 10)
            .padding(.bottom, 28)
        }
        .background(Color.appBackground)
        .task {
            loadPortraitImage()
            loadCountry()
            loadLifespan()
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
        VStack(spacing: 20) {
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
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
    }
}

private struct ProfilePill: View {
    let text: String
    let systemImage: String

    var body: some View {
        Label(text.uppercased(), systemImage: systemImage)
            .font(.caption)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
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
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
