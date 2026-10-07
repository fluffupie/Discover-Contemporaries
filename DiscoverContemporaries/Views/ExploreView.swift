import SwiftUI

struct ExploreView: View {
    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {

            VStack(
                alignment: .leading,
                spacing: 24
            ) {
                LazyVGrid(
                    columns: columns,
                    spacing: 14
                ) {
                    NavigationLink {
                        RegionView()
                    } label: {
                        ExploreCard(
                            title: "By Region",
                            subtitle: "Explore figures around the world",
                            systemImage: "globe",
                            backgroundColor: .minty
                        )
                    }
                    .buttonStyle(ExploreButtonStyle())

                    NavigationLink {
                        EraView()
                    } label: {
                        ExploreCard(
                            title: "By Era",
                            subtitle: "Browse historical time periods",
                            systemImage: "calendar",
                            backgroundColor: Color.lavender
                        )
                    }
                    .buttonStyle(ExploreButtonStyle())
                }

                NavigationLink {
                    JobsView()
                } label: {
                    ExploreWideCard(
                        title: "By Occupation",
                        subtitle:
                            "Discover artists, scientists, rulers, writers and more",
                        systemImage: "paintpalette.fill",
                        backgroundColor: Color.peach
                    )
                }
                .buttonStyle(ExploreButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .padding(.bottom, 32)

        }
        .background(Color.appBackground)
        .navigationTitle("Explore")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ExploreCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let backgroundColor: Color

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.45))
                        .frame(width: 46, height: 46)

                    Image(systemName: systemImage)
                        .font(.system(size: 21, weight: .semibold))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.secondaryText)
            }
            Spacer()

            Text(title)
                .font(.headline)
                .foregroundStyle(Color.primaryText)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(Color.secondaryText)
                .lineLimit(2)
        }
        .frame(
            maxWidth: .infinity,
            minHeight: 150,
            alignment: .leading
        )
        .padding(16)
        .background(backgroundColor)
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    Color.black.opacity(0.08),
                    lineWidth: 1
                )
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
        .shadow(
            color: .black.opacity(0.06),
            radius: 5,
            y: 2
        )
    }
}

struct ExploreWideCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let backgroundColor: Color

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.45))
                    .frame(width: 46, height: 46)

                Image(systemName: systemImage)
                    .font(.system(size: 21, weight: .semibold))
            }

            VStack(
                alignment: .leading,
                spacing: 5
            ) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.primaryText)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.secondaryText)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.secondaryText)
        }
        .padding(18)
        .background(backgroundColor)
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    Color.black.opacity(0.08),
                    lineWidth: 1
                )
        }
        .clipShape(
            RoundedRectangle(cornerRadius: 16)
        )
        .shadow(
            color: .black.opacity(0.06),
            radius: 5,
            y: 2
        )
    }
}

private struct ExploreButtonStyle: ButtonStyle {
    func makeBody(
        configuration: Configuration
    ) -> some View {
        configuration.label
            .scaleEffect(
                configuration.isPressed
                    ? 0.97
                    : 1
            )
            .opacity(
                configuration.isPressed
                    ? 0.85
                    : 1
            )
            .animation(
                .easeOut(duration: 0.12),
                value: configuration.isPressed
            )
    }
}
