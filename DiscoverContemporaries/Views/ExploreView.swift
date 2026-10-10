import SwiftUI
import SwiftData

struct ExploreView: View {
    /// Historical figures retrieved from the local SwiftData cache
    @Query(sort: \CachedHistoricalFigure.name)
    private var cachedFigures: [CachedHistoricalFigure]
    
    /// The two-column grid layout used for exploration cards.
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
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Explore by region")
                        .accessibilityValue("Explore figures around the world")
                        .accessibilityHint("Opens regional exploration")
                    }
                    .buttonStyle(ExploreButtonStyle())
                    
                    NavigationLink {
                        OccupationView()
                    } label: {
                        ExploreCard(
                            title: "By Occupation",
                            subtitle:
                                "Discover artists, scientists, rulers, writers and more",
                            systemImage: "paintpalette.fill",
                            backgroundColor: Color.lavender
                        )
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Explore by occupation")
                        .accessibilityValue("Discover artists, scientists, rulers, writers and more")
                        .accessibilityHint("Opens occupation-based exploration")
                    }
                    .buttonStyle(ExploreButtonStyle())
                }
                
                NavigationLink {
                    HistoryTimelineView(
                        figures: cachedFigures.map(\.historicalFigure)
                    )
                } label: {
                    ExploreWideCard(
                        title: "Explore the timeline",
                        subtitle: "See historical figures across time",
                        systemImage: "timeline.selection",
                        backgroundColor: Color.peach
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Explore the timeline")
                    .accessibilityValue("See historical figures across time")
                    .accessibilityHint("Opens the historical timeline")
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
                        .accessibilityHidden(true)

                    Image(systemName: systemImage)
                        .font(.title3.weight(.semibold))
                        .accessibilityHidden(true)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.cardSecondaryText)
                    .accessibilityHidden(true)
            }
            Spacer()

            Text(title)
                .font(.headline)
                .foregroundStyle(Color.black.opacity(0.85))

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(Color.cardSecondaryText)
                .fixedSize(horizontal: false, vertical: true)
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
                    .accessibilityHidden(true)

                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .accessibilityHidden(true)
            }

            VStack(
                alignment: .leading,
                spacing: 5
            ) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.black.opacity(0.85))

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.cardSecondaryText)
                    .multilineTextAlignment(.leading)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.cardSecondaryText)
                .accessibilityHidden(true)
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
#Preview {
    @MainActor
    func makePreviewContainer() -> ModelContainer {
        let schema = Schema([
            CachedHistoricalFigure.self
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Failed to create preview ModelContainer: \(error)")
        }
    }

    let container = makePreviewContainer()

    return NavigationStack {
        ExploreView()
    }
    .modelContainer(container)
}

