import SwiftData
import SwiftUI

// MARK: - Profile View

/// A view that displays detailed information about a historical figure.
///
/// Presents the figure's portrait, name, historical background,
/// lifespan, birthplace, and associated movements.
///
/// Users can:
/// - View the figure's historical information.
/// - Save or remove the figure from bookmarks.
/// - Discover contemporaries of the selected figure.
/// - Navigate to a comparison with another historical figure.
///
/// The view uses ``ProfileViewModel`` to manage figure data,
/// bookmark state, and feedback messages.
struct ProfileView: View {
    
    /// The SwiftData model context used to load and cache figure information.
    @Environment(\.modelContext)
    private var modelContext

    /// The view model responsible for profile content and bookmark state.
    @StateObject
    private var model: ProfileViewModel

    init(figure: HistoricalFigure) {
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
                spacing: 20
            ) {
                ProfileHero(
                    figure: model.figure,
                    imageName: model.imageName,
                    imageURL: model.imageURL,
                    roleLabel: model.roleLabel,
                    birthPlace: model.birthPlace
                )

                ProfileSection(title: "Summary") {
                    Text(model.summaryText)
                        .font(.system(.body, design: .monospaced))
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
                            value: model.movementText
                        )
                    }
                }

                ProfileSection(
                    title: "Contemporaries"
                ) {
                    NavigationLink {
                        ContemporariesView(
                            figure: model.resolvedFigure
                        )
                    } label: {
                        Label(
                            "See all",
                            systemImage: "person.2.fill"
                        )
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(red: 0.0, green: 0.35, blue: 0.25))
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 6
                            )
                        )
                        .accessibilityHint("Opens contemporaries for \(model.figure.name)")
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 6)
            .padding(.bottom, 28)
        }
        .background(Color.appBackground)
        .overlay(alignment: .top) {
            if let message = model.bookmarkMessage {
                ToastBanner(message: message)
                    .transition(
                        .move(edge: .top)
                            .combined(with: .opacity)
                    )
                    .zIndex(1)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: model.bookmarkMessage) {
            guard model.bookmarkMessage != nil else { return }
            try? await Task.sleep(for: .seconds(1.8))
            model.clearBookmarkMessage()
        }
        .animation(.default, value: model.bookmarkMessage)
        .toolbar {
            ToolbarItem(
                placement: .topBarTrailing
            ) {
                Button {
                    Task { await model.toggleBookmark() }
                } label: {
                    Image(systemName: model.isBookmarked ? "heart.fill" : "heart")
                        .foregroundStyle(model.isBookmarked ? Color.red : Color.primary)
                        .font(.subheadline.weight(.semibold))
                        .accessibilityLabel(
                            model.isBookmarked ? "Remove from bookmarks" : "Save to bookmarks"
                        )
                        .accessibilityHint(
                            model.isBookmarked
                                ? "Removes this figure from your bookmarks"
                                : "Saves this figure to your bookmarks"
                        )
                }
                .disabled(model.isUpdatingBookmark)
            }

            ToolbarItem(
                placement: .topBarTrailing
            ) {
                NavigationLink {
                    CompareSearchView(
                        firstFigure: model.resolvedFigure
                    )
                } label: {
                    Image(
                        systemName: "arrow.left.arrow.right"
                    )
                    .font(.subheadline.weight(.semibold))
                    .accessibilityLabel("Compare")
                }
            }
        }
        .task {
            await model.load(context: modelContext)
        }
        .task {
            await model.loadBookmarkState()
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
            .frame(minWidth: 0, maxWidth: .infinity)
            .accessibilityHidden(true)
            .clipShape(
                RoundedRectangle(cornerRadius: 10)
            )

            VStack(spacing: 8) {
                Text(figure.name)
                    .font(.system(.title, design: .serif).weight(.semibold))
                    .foregroundStyle(Color.black.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)

                ViewThatFits {
                    HStack(spacing: 8) {
                        ProfilePill(text: roleLabel, systemImage: "sparkle")
                        ProfilePill(text: birthPlace, systemImage: "globe")
                    }
                    VStack(spacing: 8) {
                        ProfilePill(text: roleLabel, systemImage: "sparkle")
                        ProfilePill(text: birthPlace, systemImage: "globe")
                    }
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(figure.name)
            .accessibilityValue("\(roleLabel). \(birthPlace)")
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 14)
    }
}

// MARK: - Profile Pill

private struct ProfilePill: View {
    let text: String
    let systemImage: String

    var body: some View {
        Label(text.uppercased(), systemImage: systemImage)
            .font(.caption)
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.coral.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16))
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
                .fontDesign(.rounded)

            content
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }
}

// MARK: - Fact Row
/// A reusable row displaying a labelled historical fact.
///
/// Used in the profile's details section to display information
/// such as lifespan, age, birthplace, and historical movement.
private struct FactRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(
            alignment: .top,
            spacing: 14
        ) {
            Image(systemName: icon)
                .font(
                    .headline
                )
                .foregroundStyle(Color.emerald)
                .frame(width: 25)
                .accessibilityHidden(true)

            VStack(
                alignment: .leading,
                spacing: 2
            ) {
                Text(label)
                    .font(.caption)
                    .fontDesign(.monospaced)
                    .foregroundStyle(Color.secondaryText)

                Text(value)
                    .font(
                        .subheadline
                    )
                    .fontDesign(.default)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.black.opacity(0.85))
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue(value)
    }
}

// MARK: - Toast Banner
/// A temporary notification banner used to display bookmark feedback.
///
/// Displays a message inside a dark capsule-shaped background.
///
/// The banner is presented by ``ProfileView`` when the view model
/// provides a bookmark message, and is cleared after a short delay.
private struct ToastBanner: View {
    
    /// The feedback message displayed in the banner.
    let message: String

    var body: some View {
        Text(message)
            .font(.caption.weight(.regular))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Color.black.opacity(0.85)
            )
            .clipShape(Capsule())
            .padding(.top, 10)
    }
}

#Preview {
    // Helper to construct a date from year, month, day
    func date(_ year: Int, _ month: Int = 1, _ day: Int = 1) -> Date {
        Calendar(identifier: .gregorian)
            .date(from: DateComponents(year: year, month: month, day: day))!
    }

    let sample = HistoricalFigure(
        id: "Q13133",
        name: "Jennifer Aniston",
        descriptionText: "American actress and producer",
        gender: "female",
        birthPlace: "Los Angeles, California, U.S.",
        birthDate: date(1969, 2, 11),
        deathDate: nil,
        occupations: ["Actor", "Producer"],
        movements: [],
        imageURL: URL(string: "https://upload.wikimedia.org/wikipedia/commons/1/16/JenniferAnistonHWoFFeb2012.jpg"),
        imageName: nil
    )

    return NavigationStack {
        ProfileView(figure: sample)
    }
}
