import SwiftUI

struct LifespanCompareView: View {
    let firstFigure: HistoricalFigure
    let secondFigure: HistoricalFigure

    private var firstRange: LifeRange? {
        LifeRange(birthDate: firstFigure.birthDate, deathDate: firstFigure.deathDate)
    }

    private var secondRange: LifeRange? {
        LifeRange(birthDate: secondFigure.birthDate, deathDate: secondFigure.deathDate)
    }

    private var overlapYears: Int {
        guard let firstRange,
              let secondRange,
              let overlap = LifeRange.overlap(firstRange, secondRange) else {
            return 0
        }

        return overlap.completedYears
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                CompareProfilePanel(
                    figure: firstFigure,
                    range: firstRange,
                    background: AnyShapeStyle(Color.firstCompareGradient),
                    cornerRadius: 34,
                    usesSoftGradientBackground: true,
                    showsGlowBadge: false
                )

                Text(firstFigure.name)
                    .font(.h1Title)
                    .tracking(1.2)
                    .foregroundStyle(Color.compareRed)
                    .multilineTextAlignment(.center)

                LifespanTimeline(
                    firstFigure: firstFigure,
                    secondFigure: secondFigure,
                    firstRange: firstRange,
                    secondRange: secondRange
                )

                CompareProfilePanel(
                    figure: secondFigure,
                    range: secondRange,
                    background: AnyShapeStyle(Color.compareMint),
                    cornerRadius: 28,
                    usesSoftGradientBackground: false,
                    showsGlowBadge: false
                )

                Text(secondFigure.name)
                    .font(.h1Title)
                    .tracking(1.2)
                    .foregroundStyle(Color.compareGreen)
                    .multilineTextAlignment(.center)

                VStack(spacing: 12) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.compareGold)

                    Text("They Were On The Earth Together For")
                        .font(.h1Title)
                        .tracking(1.1)
                        .foregroundStyle(Color.primaryText)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 4) {
                        Text("\(overlapYears)")
                            .foregroundStyle(Color.red)
                        Text(overlapYears == 1 ? "Year" : "Years")
                            .foregroundStyle(Color.primaryText)
                    }
                    .font(.system(size: 24, weight: .bold))
                }
                .padding(.top, 14)
                .padding(.bottom, 22)
            }
            .padding(.horizontal, 28)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
        .background(Color.appBackground)
        .navigationTitle("Compare")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct CompareProfilePanel: View {
    let figure: HistoricalFigure
    let range: LifeRange?
    let background: AnyShapeStyle
    let cornerRadius: CGFloat
    let usesSoftGradientBackground: Bool
    let showsGlowBadge: Bool

    private var regionName: String {
        figure.birthPlace ?? "Global"
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            HStack(spacing: 26) {
                PortraitImage(imageURL: figure.imageURL)
                    .frame(width: 120, height: 120)
                    .clipped()

                VStack(alignment: .leading, spacing: 10) {
                    Text("PROFILE")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.86))

                    ProfilePill(systemImage: "gift.fill", text: range?.yearText ?? figure.lifespan)
                    ProfilePill(systemImage: "mappin.circle.fill", text: regionName.uppercased())

                    HStack(alignment: .top, spacing: 8) {
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 3)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("AGE")
                                .font(.system(size: 13, weight: .medium))
                            Text(range.map { "\($0.completedYears) Years" } ?? "Unknown")
                                .font(.system(size: 15, weight: .regular))
                        }
                        .foregroundStyle(.white)

                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 8)
                    .background(Color.white.opacity(0.16))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
            .padding(22)
            .background {
                ComparePanelBackground(
                    background: background,
                    cornerRadius: cornerRadius,
                    usesSoftGradient: usesSoftGradientBackground
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))

            if showsGlowBadge {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .bold))
                    Text("Glow")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.comparePurple)
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .offset(x: -10, y: -16)
            }
        }
    }
}

private struct ComparePanelBackground: View {
    let background: AnyShapeStyle
    let cornerRadius: CGFloat
    let usesSoftGradient: Bool

    var body: some View {
        ZStack {
            if usesSoftGradient {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(red: 0.91, green: 0.70, blue: 0.68))

                Rectangle()
                    .fill(background)
                    .frame(width: 350, height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .blur(radius: 50)
                    .opacity(0.6)
            } else {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(background)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

private struct ProfilePill: View {
    let systemImage: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.85))
                .frame(width: 24, height: 24)
                .background(Color.white)
                .clipShape(Circle())

            Text(text)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer(minLength: 0)
        }
        .padding(.trailing, 12)
        .frame(height: 32)
        .background(Color.white.opacity(0.18))
        .clipShape(Capsule())
    }
}

private struct LifespanTimeline: View {
    let firstFigure: HistoricalFigure
    let secondFigure: HistoricalFigure
    let firstRange: LifeRange?
    let secondRange: LifeRange?

    private var startYear: Int {
        min(firstRange?.startYear ?? 0, secondRange?.startYear ?? 0)
    }

    private var endYear: Int {
        max(firstRange?.endYear ?? 1, secondRange?.endYear ?? 1)
    }

    var body: some View {
        VStack(spacing: 8) {
            GeometryReader { proxy in
                let width = proxy.size.width

                VStack(spacing: 6) {
                    if let firstRange {
                        TimelineBar(
                            title: firstFigure.shortName,
                            color: Color.compareRed,
                            range: firstRange,
                            startYear: startYear,
                            endYear: endYear,
                            width: width
                        )
                    }

                    Rectangle()
                        .fill(Color.black.opacity(0.22))
                        .frame(height: 4)
                        .padding(.vertical, 4)

                    if let secondRange {
                        TimelineBar(
                            title: secondFigure.shortName,
                            color: Color.compareGreen,
                            range: secondRange,
                            startYear: startYear,
                            endYear: endYear,
                            width: width
                        )
                    }
                }
            }
            .frame(height: 82)

            HStack {
                Text("\(startYear)")
                Spacer()
                Text("\(endYear)")
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(Color.secondaryText)
        }
        .padding(.horizontal, 10)
    }
}

private struct TimelineBar: View {
    let title: String
    let color: Color
    let range: LifeRange
    let startYear: Int
    let endYear: Int
    let width: CGFloat

    private var totalYears: CGFloat {
        CGFloat(max(1, endYear - startYear))
    }

    private var leadingOffset: CGFloat {
        CGFloat(range.startYear - startYear) / totalYears * width
    }

    private var barWidth: CGFloat {
        CGFloat(range.endYear - range.startYear) / totalYears * width
    }

    var body: some View {
        ZStack(alignment: .leading) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: max(44, barWidth), height: 30)
                .background(color.opacity(0.16))
                .padding(.leading, leadingOffset)
        }
        .frame(width: width, height: 30, alignment: .leading)
    }
}

private struct LifeRange {
    let startDate: Date
    let endDate: Date
    let startYear: Int
    let endYear: Int
    let completedYears: Int

    var yearText: String {
        "\(startYear) - \(endYear)"
    }

    init?(birthDate: Date?, deathDate: Date?) {
        guard let startDate = birthDate else {
            return nil
        }

        let endDate = deathDate ?? Date()

        self.startDate = startDate
        self.endDate = endDate
        self.startYear = Calendar.current.component(.year, from: startDate)
        self.endYear = Calendar.current.component(.year, from: endDate)
        self.completedYears = Calendar.current.dateComponents([.year], from: startDate, to: endDate).year ?? 0
    }

    private init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
        self.startYear = Calendar.current.component(.year, from: startDate)
        self.endYear = Calendar.current.component(.year, from: endDate)
        self.completedYears = Calendar.current.dateComponents([.year], from: startDate, to: endDate).year ?? 0
    }

    static func overlap(_ first: LifeRange, _ second: LifeRange) -> LifeRange? {
        let startDate = max(first.startDate, second.startDate)
        let endDate = min(first.endDate, second.endDate)

        guard startDate < endDate else {
            return nil
        }

        return LifeRange(startDate: startDate, endDate: endDate)
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

private extension HistoricalFigure {
    var shortName: String {
        name.split(separator: " ").last.map(String.init) ?? name
    }
}
