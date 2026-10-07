import SwiftUI

struct ComparisonView: View {
    let firstFigure: HistoricalFigure
    let secondFigure: HistoricalFigure

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 15) {
                    CompareCard(figure: firstFigure)
                    CompareCard(figure: secondFigure)
                }

                // overlapping visuals here
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
                            "Both figures need birth and death dates."
                        )
                    )
                }

            }
            .padding(20)
        }
        .background(Color.appBackground)
        .navigationTitle("Compare")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var timelineData: LifespanTimelineData? {
        LifespanTimelineData(
            firstFigure: firstFigure,
            secondFigure: secondFigure
        )
    }

    private struct LifespanTimeline: View {
        let firstFigure: HistoricalFigure
        let secondFigure: HistoricalFigure
        let timeline: LifespanTimelineData

        var body: some View {
            VStack(alignment: .leading, spacing: 18) {
                overlapHeader

                yearScale

                figureTimeline(
                    figure: firstFigure,
                    birthYear: timeline.firstBirthYear,
                    deathYear: timeline.firstDeathYear
                )

                figureTimeline(
                    figure: secondFigure,
                    birthYear: timeline.secondBirthYear,
                    deathYear: timeline.secondDeathYear
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

        private var noOverlapView: some View {
            HStack(spacing: 8) {
                Image(systemName: "calendar.badge.minus")

                Text("Their lifespans did not overlap.")
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(Color.secondaryText)
            .padding(.vertical, 8)
        }

        private var overlapHeader: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(timeline.overlapYears) years")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Color.primaryText)

                Text("alive at the same time")
                    .font(.subheadline)
                    .foregroundStyle(Color.secondaryText)
            }
        }

        private var yearScale: some View {
            VStack(spacing: 4) {
                HStack {
                    tickLabel(timeline.startYear)

                    Spacer()

                    tickLabel(timeline.middleYear)

                    Spacer()

                    tickLabel(timeline.endYear)
                }

                Rectangle()
                    .fill(Color.secondaryText.opacity(0.25))
                    .frame(height: 1)
            }
        }

        private func tickLabel(_ year: Int) -> some View {
            VStack(spacing: 3) {
                Text("\(year)")
                    .font(.caption2)
                    .foregroundStyle(Color.secondaryText)

                Rectangle()
                    .fill(Color.secondaryText.opacity(0.35))
                    .frame(width: 1, height: 5)
            }
        }

        private func figureTimeline(
            figure: HistoricalFigure,
            birthYear: Int,
            deathYear: Int
        ) -> some View {
            VStack(alignment: .leading, spacing: 8) {
                Text(figure.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primaryText)

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.12))
                            .frame(height: 12)

                        Capsule()
                            .fill(Color.tealButton)
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
                    }
                }
                .frame(height: 12)
            }
        }

        private var overlapBar: some View {
            VStack(alignment: .leading, spacing: 8) {
                Text("Shared lifetime")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.primaryText)

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
                            .fill(Color.tealButton.opacity(0.35))
                            .frame(width: width, height: 16)

                        HStack {
                            Text("\(timeline.overlapStartYear)")
                            Spacer()
                            Text("\(timeline.overlapEndYear)")
                        }
                        .frame(width: width)
                        .font(.caption2)
                        .foregroundStyle(Color.secondaryText)
                    }
                    .offset(x: offset)
                }
                .frame(height: 38)
            }
        }

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

        let secondBirthYear: Int
        let secondDeathYear: Int

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
                let firstDeath = firstFigure.deathDate,
                let secondBirth = secondFigure.birthDate,
                let secondDeath = secondFigure.deathDate
            else {
                return nil
            }

            let calendar = Calendar(identifier: .gregorian)

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
    }
}
