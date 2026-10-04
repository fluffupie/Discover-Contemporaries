import SwiftData
import SwiftUI

struct ProfileView: View {

    @Environment(\.modelContext) private var modelContext

    let figure: HistoricalFigure

    @StateObject private var model: ProfileViewModel

    init(figure: HistoricalFigure) {
        self.figure = figure

        _model = StateObject(
            wrappedValue: ProfileViewModel(
                figure: figure
            )
        )
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(
                alignment: .leading,
                spacing: 24
            ) {
                ProfileHero(
                    figure: model.figure,
                    imageName: model.imageName,
                    imageURL: model.imageURL,
                    roleLabel: model.figure.primaryOccupation,
                    birthPlace: model.birthPlace
                )

                ProfileSection(title: "Summary") {
                    Text(
                        model.figure.descriptionText
                            ?? "No description available yet."
                    )
                    .font(
                        .system(
                            .body,
                            design: .serif
                        )
                    )
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
                }

                ProfileSection(title: "Details") {
                    VStack(spacing: 10) {
                        FactRow(
                            icon: "calendar",
                            label: "Lifespan",
                            value: model.lifespanText
                        )

                        FactRow(
                            icon: "hourglass",
                            label: "Age",
                            value: model.ageText
                        )

                        FactRow(
                            icon: "globe",
                            label: "Birthplace",
                            value: model.birthPlace
                        )

                        FactRow(
                            icon: "sparkles",
                            label: "Movement",
                            value: model.figure.movementsText
                        )
                    }
                }

                ProfileSection(
                    title: "Contemporaries"
                ) {
                    NavigationLink {
                        ContemporariesView(
                            figure: model.figure
                        )
                    } label: {
                        Label(
                            "See all",
                            systemImage: "person.2.fill"
                        )
                        .font(
                            .system(
                                size: 14,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(.white)
                        .frame(
                            maxWidth: .infinity
                        )
                        .padding(.vertical, 12)
                        .background(
                            Color.tealButton
                        )
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 6
                            )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 6)
            .padding(.bottom, 28)
        }
        .background(Color.appBackground)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SearchAndCompareView(firstFigure: model.figure)
                } label: {
                    Image(systemName: "arrow.left.and.right")
                        .font(.system(size: 16, weight: .semibold))
                        .accessibilityLabel("Compare with someone")
                }
            }
        }
        .task {
            let repository =
                FigureCacheRepository(
                    context: modelContext
                )

            model.load(
                repository: repository
            )
        }
    }
}

// MARK: - Hero

private struct ProfileHero: View {

    let figure: HistoricalFigure
    let imageName: String?
    let imageURL: URL?
    let roleLabel: String
    let birthPlace: String

    var body: some View {
        VStack(spacing: 20) {
            PortraitImage(
                imageName: imageName,
                imageURL: imageURL
            )
            .frame(
                width: 154,
                height: 154
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 10
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 10
                )
                .stroke(
                    Color.white.opacity(0.85),
                    lineWidth: 3
                )
            }
            .shadow(
                color: .black.opacity(0.16),
                radius: 12,
                y: 7
            )

            VStack(spacing: 8) {
                Text(figure.name)
                    .font(
                        .system(
                            size: 28,
                            weight: .semibold,
                            design: .serif
                        )
                    )
                    .foregroundStyle(
                        Color.primaryText
                    )
                    .multilineTextAlignment(
                        .center
                    )
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)

                HStack(spacing: 8) {
                    ProfilePill(
                        text: roleLabel,
                        systemImage: "sparkle"
                    )

                    ProfilePill(
                        text: birthPlace,
                        systemImage: "globe"
                    )
                }
                .frame(
                    maxWidth: .infinity
                )
            }
        }
        .frame(
            maxWidth: .infinity
        )
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
    }
}

// MARK: - Profile Pill

private struct ProfilePill: View {

    let text: String
    let systemImage: String

    var body: some View {
        Label(
            text.uppercased(),
            systemImage: systemImage
        )
        .font(.caption)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Color.ochre.opacity(0.08)
        )
        .clipShape(Capsule())
    }
}

// MARK: - Profile Section

private struct ProfileSection<Content: View>: View {

    let title: String

    @ViewBuilder
    let content: Content

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            Text(title)
                .font(.headline)

            content
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }
}

// MARK: - Fact Row

private struct FactRow: View {

    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(
            alignment: .top,
            spacing: 10
        ) {
            Image(
                systemName: icon
            )
            .font(
                .system(
                    size: 14,
                    weight: .semibold
                )
            )
            .foregroundStyle(
                Color.tealButton
            )
            .frame(width: 22)

            VStack(
                alignment: .leading,
                spacing: 2
            ) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(
                        Color.secondaryText
                    )

                Text(value)
                    .font(
                        .system(
                            size: 14,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(
                        Color.primaryText
                    )
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }

            Spacer(minLength: 0)
        }
    }
}

