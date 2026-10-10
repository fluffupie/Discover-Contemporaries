import SwiftUI

/// A view that presents a side-by-side comparison for two `HistoricalFigure` values.
///
/// The comparison includes quick navigation to each profile and a timeline
/// that highlights life spans and any overlapping years.
///
/// - Parameters:
///   - firstFigure: The primary figure to compare.
///   - secondFigure: The secondary figure to compare against the primary.
struct ComparisonView: View {
    let firstFigure: HistoricalFigure
    let secondFigure: HistoricalFigure

    /// The content and behavior of the comparison view.
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 15) {
                    NavigationLink {
                        ProfileView(figure: firstFigure)
                    } label: {
                        CompareCard(figure: firstFigure)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel(firstFigure.name)
                            .accessibilityValue(firstFigure.lifespan)
                            .accessibilityHint("Opens profile")
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        ProfileView(figure: secondFigure)
                    } label: {
                        CompareCard(figure: secondFigure)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel(secondFigure.name)
                            .accessibilityValue(secondFigure.lifespan)
                            .accessibilityHint("Opens profile")
                    }
                    .buttonStyle(.plain)
                }

                if let timeline = timelineData {
                    LifespanTimeline(
                        firstFigure: firstFigure,
                        secondFigure: secondFigure,
                        timeline: timeline
                    )
                } else {
                    ContentUnavailableView(
                        "Unable to compare",
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text(
                            "Both figures need a known birth date."
                        )
                    )
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Unable to compare lifespans")
                    .accessibilityHint("Birth dates are required for both figures")
                }

            }
            .padding(20)
        }
        .background(Color.appBackground)
        .navigationTitle("Compare")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Lazily computed timeline data derived from the two figures.
    /// Returns `nil` when required birth dates are missing.
    private var timelineData: LifespanTimelineData? {
        LifespanTimelineData(
            firstFigure: firstFigure,
            secondFigure: secondFigure
        )
    }

    /// A visual timeline component that renders the life spans of two figures
    /// on a shared horizontal scale and, when applicable, their overlapping years.
    private struct LifespanTimeline: View {
        let firstFigure: HistoricalFigure
        let secondFigure: HistoricalFigure
       
        let timeline: LifespanTimelineData

        /// The timeline layout including headers, scale, individual bars,
        /// and the shared overlap indicator.
        var body: some View {
            VStack(alignment: .leading, spacing: 18) {

                if timeline.hasOverlap {
                    overlapHeader
                }

                yearScale

                figureTimeline(
                    figure: firstFigure,
                    birthYear: timeline.firstBirthYear,
                    deathYear: timeline.firstDeathYear,
                    isLiving: timeline.firstIsLiving
                )

                figureTimeline(
                    figure: secondFigure,
                    birthYear: timeline.secondBirthYear,
                    deathYear: timeline.secondDeathYear,
                    isLiving: timeline.secondIsLiving
                )

                if timeline.hasOverlap {
                    overlapBar
                } else {
                    noOverlapView
                }
            }
            .padding(18)
            .background(Color.white)
            .clipShape(
                RoundedRectangle(cornerRadius: 14)
            )
        }

        /// A compact message shown when the two figures' lifespans do not overlap.
        private var noOverlapView: some View {
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.minus")
                    .accessibilityHidden(true)
                
                Text("Their lifespans did not overlap.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.secondaryText)
            }
            .accessibilityLabel("No overlapping years")
            .padding(.vertical, 8)
        }

        /// A header summarizing the number of years the two figures were alive at the same time.
        private var overlapHeader: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(timeline.overlapYears) years")
                    .font(.title.weight(.bold))
                    .foregroundStyle(Color.black.opacity(0.85))
                
                Text("alive at the same time")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondaryText)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Overlap")
            .accessibilityValue("\(timeline.overlapYears) years alive at the same time")
        }

        /// A horizontal axis with labeled ticks for the start, middle, and end years.
        private var yearScale: some View {
            VStack(spacing: 4) {
                HStack {
                    tickLabel("\(timeline.startYear)")
                    Spacer()
                    tickLabel("\(timeline.middleYear)")
                    Spacer()
                    tickLabel(timeline.endsAtPresent ? "Present" : "\(timeline.endYear)")
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Timeline scale")
                .accessibilityValue("\(timeline.startYear) to \(timeline.endsAtPresent ? "Present" : "\(timeline.endYear)")")

                Rectangle()
                    .fill(Color.secondaryText.opacity(0.25))
                    .frame(height: 1)
                    .accessibilityHidden(true)
            }
        }

        /// Renders a small tick label and marker used by the year scale.
        /// - Parameter text: The year text to display.
        private func tickLabel(_ text: String) -> some View {
            VStack(spacing: 3) {
                Text(text)
                    .font(.caption2)
                    .foregroundStyle(Color.secondaryText)
                Rectangle()
                    .fill(Color.secondaryText.opacity(0.35))
                    .frame(width: 1, height: 5)
                    .accessibilityHidden(true)
            }
            .accessibilityHidden(true)
        }

        /// Renders a single figure's lifespan bar on the shared timeline.
        /// - Parameters:
        ///   - figure: The figure being rendered.
        ///   - birthYear: The birth year of the figure.
        ///   - deathYear: The death year of the figure.
        ///   - isLiving: Whether the figure is alive (uses "Present").
        private func figureTimeline(
            figure: HistoricalFigure,
            birthYear: Int,
            deathYear: Int,
            isLiving: Bool
        ) -> some View {
            VStack(alignment: .leading, spacing: 8) {

                HStack {
                    Text(figure.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.black.opacity(0.85))
                    Spacer()
                    Text(
                        isLiving
                            ? "\(birthYear) – Present"
                            : "\(birthYear) – \(deathYear)"
                    )
                    .font(.caption2)
                    .foregroundStyle(Color.secondaryText)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(figure.name)
                .accessibilityValue(isLiving ? "\(birthYear) to Present" : "\(birthYear) to \(deathYear)")

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.12))
                            .frame(height: 12)
                            .accessibilityHidden(true)

                        Capsule()
                            .fill(Color.emerald)
                            .frame(
                                width: barWidth(
                                    geometryWidth: geometry.size.width,
                                    startYear: birthYear,
                                    endYear: deathYear
                                ),
                                height: 12
                            )
                            .offset(
                                x: barOffset(
                                    geometryWidth: geometry.size.width,
                                    year: birthYear
                                )
                            )
                            .accessibilityHidden(true)
                    }
                }
                .frame(height: 12)
            }
        }

        /// A highlighted bar that represents the overlapping portion of the two lifespans.
        private var overlapBar: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("Shared lifetime")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.black.opacity(0.85))

                GeometryReader { geometry in
                    let offset = barOffset(
                        geometryWidth: geometry.size.width,
                        year: timeline.overlapStartYear
                    )

                    let width = barWidth(
                        geometryWidth: geometry.size.width,
                        startYear: timeline.overlapStartYear,
                        endYear: timeline.overlapEndYear
                    )

                    VStack(alignment: .leading, spacing: 4) {
                        Capsule()
                            .fill(Color.emerald.opacity(0.35))
                            .frame(width: width, height: 16)

                        HStack {
                            Text("\(timeline.overlapStartYear)")
                            Spacer()
                            Text(
                                timeline.overlapEndsAtPresent
                                    ? "Present"
                                    : "\(timeline.overlapEndYear)"
                            )
                        }
                        .frame(width: width)
                        .font(.caption2)
                        .foregroundStyle(Color.secondaryText)
                    }
                    .offset(x: offset)
                }
                .frame(height: 38)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Shared lifetime")
            .accessibilityValue(
                "\(timeline.overlapStartYear) to \(timeline.overlapEndsAtPresent ? "Present" : "\(timeline.overlapEndYear)")"
            )
        }

        /// Computes the x-offset for a year relative to the timeline's start and end.
        /// - Parameters:
        ///   - geometryWidth: The available width for the timeline.
        ///   - year: The year to position.
        /// - Returns: The leading offset in points.
        private func barOffset(
            geometryWidth: CGFloat,
            year: Int
        ) -> CGFloat {
            let totalYears = max(
                timeline.endYear - timeline.startYear,
                1
            )

            let progress =
                Double(year - timeline.startYear)
                / Double(totalYears)

            return geometryWidth * progress
        }

        /// Computes the width of a bar representing a time span on the shared scale.
        /// - Parameters:
        ///   - geometryWidth: The available width for the timeline.
        ///   - startYear: The start year of the span.
        ///   - endYear: The end year of the span.
        /// - Returns: The width in points for the span.
        private func barWidth(
            geometryWidth: CGFloat,
            startYear: Int,
            endYear: Int
        ) -> CGFloat {
            let totalYears = max(
                timeline.endYear - timeline.startYear,
                1
            )

            let duration = max(
                endYear - startYear,
                0
            )

            return geometryWidth
                * Double(duration)
                / Double(totalYears)
        }
    }

    private struct LifespanTimelineData {
        let firstBirthYear: Int
        let firstDeathYear: Int
        let firstIsLiving: Bool

        let secondBirthYear: Int
        let secondDeathYear: Int
        let secondIsLiving: Bool

        let startYear: Int
        let endYear: Int

        let overlapStartYear: Int
        let overlapEndYear: Int

        init?(
            firstFigure: HistoricalFigure,
            secondFigure: HistoricalFigure
        ) {
            guard
                let firstBirth = firstFigure.birthDate,
                let secondBirth = secondFigure.birthDate
            else {
                return nil
            }

            firstIsLiving = firstFigure.deathDate == nil
            secondIsLiving = secondFigure.deathDate == nil

            let firstDeath = firstFigure.deathDate ?? Date()
            let secondDeath = secondFigure.deathDate ?? Date()

            let calendar = Calendar(
                identifier: .gregorian
            )

            firstBirthYear = calendar.component(
                .year,
                from: firstBirth
            )

            firstDeathYear = calendar.component(
                .year,
                from: firstDeath
            )

            secondBirthYear = calendar.component(
                .year,
                from: secondBirth
            )

            secondDeathYear = calendar.component(
                .year,
                from: secondDeath
            )

            startYear = min(
                firstBirthYear,
                secondBirthYear
            )

            endYear = max(
                firstDeathYear,
                secondDeathYear
            )

            overlapStartYear = max(
                firstBirthYear,
                secondBirthYear
            )

            overlapEndYear = min(
                firstDeathYear,
                secondDeathYear
            )
        }

        var hasOverlap: Bool {
            overlapEndYear >= overlapStartYear
        }

        var overlapYears: Int {
            guard hasOverlap else {
                return 0
            }

            return overlapEndYear - overlapStartYear
        }

        var middleYear: Int {
            startYear + ((endYear - startYear) / 2)
        }

        var endsAtPresent: Bool {
            firstIsLiving || secondIsLiving
        }
        
        var overlapEndsAtPresent: Bool {
            firstIsLiving && secondIsLiving
        }
    }
}

#Preview {
    // Helper to construct a date from year, month, day
    func date(_ year: Int, _ month: Int = 1, _ day: Int = 1) -> Date {
        Calendar(identifier: .gregorian)
            .date(from: DateComponents(year: year, month: month, day: day))!
    }

    let ada = HistoricalFigure(
        id: "Q7259",
        name: "Ada Lovelace",
        descriptionText: "Mathematician and writer",
        gender: "female",
        birthPlace: "London, England",
        birthDate: date(1815, 12, 10),
        deathDate: date(1852, 11, 27),
        occupations: ["Mathematician", "Writer"],
        movements: [],
        imageURL: nil,
        imageName: nil
    )

    let turing = HistoricalFigure(
        id: "Q7251",
        name: "Alan Turing",
        descriptionText: "Computer scientist and mathematician",
        gender: "male",
        birthPlace: "London, England",
        birthDate: date(1912, 6, 23),
        deathDate: date(1954, 6, 7),
        occupations: ["Computer scientist", "Mathematician"],
        movements: [],
        imageURL: nil,
        imageName: nil
    )

    return NavigationStack {
        ComparisonView(firstFigure: ada, secondFigure: turing)
    }
}
