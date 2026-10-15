import Combine
import CoreGraphics
import Foundation

/// Manages timeline layout, selection, ruler generation and zoom state.
@MainActor
final class TimelineViewModel: ObservableObject {

    // MARK: - Layout Constants

    static let defaultScale: CGFloat = 4
    static let minScale: CGFloat = 0.1
    static let maxScale: CGFloat = 40
    static let rowHeight: CGFloat = 34
    static let rowSpacing: CGFloat = 6
    static let rulerHeight: CGFloat = 26
    static let minBarWidth: CGFloat = 56
    static let barGap: CGFloat = 6
    static let horizontalPadding: CGFloat = 24

    /// Year intervals the ruler can use, smallest first.
    private static let tickStepCandidates = [1, 2, 5, 10, 25, 50, 100, 250, 500, 1000, 2500]

    /// The minimum spacing in points between two ruler ticks.
    private static let minTickSpacing: CGFloat = 70

    private static let fallbackTickStep = 5000

    // MARK: - Data

    /// The entries in start-year order. Longer spans come first on ties.
    let entries: [TimelineEntry]

    /// How many figures were dropped for lacking usable timeline dates.
    let skippedCount: Int

    /// The figure selected when the timeline first appears.
    let highlightedID: String?

    /// The earliest starting year, or 0 when there are no entries.
    let minYear: Int

    /// The latest ending year, or 1 when there are no entries.
    let maxYear: Int

    private let entriesByID: [String: TimelineEntry]

    // MARK: - State

    @Published private(set) var pointsPerYear: CGFloat = TimelineViewModel.defaultScale
    @Published private(set) var rows: [String: Int] = [:]
    @Published var selectedID: String?
    @Published private var storedOffset: CGSize = .zero

    /// The number of rows needed to show every bar without overlap.
    ///
    /// Updated together with ``rows``, so it changes whenever `rows` does.
    private(set) var rowCount = 0

    /// The visible size of the canvas, reported by the view.
    ///
    /// Not published. Set it from `onChange(of:)` rather than during `body`.
    var viewportSize: CGSize = .zero

    private var pinchAnchor: CGFloat?
    private var lastPanTranslation: CGSize = .zero

    // MARK: - Init

    /// Creates timeline entries from figures and prepares the initial layout.
    ///
    /// Duplicate figures are removed, figures without usable timeline dates
    /// are skipped, and the rest are ordered by starting year.
    ///
    /// - Parameters:
    ///   - figures: The figures to display.
    ///   - highlightedID: An optional figure ID to select initially.
    init(
        figures: [HistoricalFigure],
        highlightedID: String? = nil
    ) {
        var seen = Set<String>()
        let unique = figures.filter { seen.insert($0.id).inserted }

        let built = unique
            .compactMap { TimelineEntry(figure: $0) }
            .sorted {
                $0.startYear == $1.startYear
                    ? $0.span > $1.span
                    : $0.startYear < $1.startYear
            }

        let layout = Self.packRows(built, scale: Self.defaultScale)

        self.entries = built
        self.entriesByID = Dictionary(
            built.map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        self.skippedCount = unique.count - built.count
        self.minYear = built.map(\.startYear).min() ?? 0
        self.maxYear = built.map(\.endYear).max() ?? 1
        self.highlightedID = highlightedID
        self.selectedID = highlightedID
        self.rows = layout.rows
        self.rowCount = layout.count
    }

    // MARK: - Selection

    /// The selected entry, if any.
    var selectedEntry: TimelineEntry? {
        selectedID.flatMap { entriesByID[$0] }
    }

    /// Selects an entry, or deselects it if it's already selected.
    func select(_ entry: TimelineEntry) {
        selectedID = selectedID == entry.id ? nil : entry.id
    }

    // MARK: - Geometry

    /// The total horizontal width needed at the current scale.
    var totalWidth: CGFloat {
        CGFloat(maxYear - minYear) * pointsPerYear
            + Self.horizontalPadding * 2
            + Self.minBarWidth
    }

    /// The total vertical height needed for the current rows.
    var contentHeight: CGFloat {
        Self.rulerHeight
            + CGFloat(rowCount) * (Self.rowHeight + Self.rowSpacing)
            + 16
    }

    /// The horizontal position of a year, in points.
    func xOffset(forYear year: Int) -> CGFloat {
        Self.horizontalPadding + CGFloat(year - minYear) * pointsPerYear
    }

    /// The horizontal position of an entry's bar, in points.
    func xOffset(for entry: TimelineEntry) -> CGFloat {
        xOffset(forYear: entry.startYear)
    }

    /// The width of an entry's bar, in points.
    func width(for entry: TimelineEntry) -> CGFloat {
        max(Self.minBarWidth, CGFloat(entry.span) * pointsPerYear)
    }

    /// The vertical position of an entry's bar, in points.
    func yOffset(for entry: TimelineEntry) -> CGFloat {
        Self.rulerHeight
            + CGFloat(rows[entry.id] ?? 0) * (Self.rowHeight + Self.rowSpacing)
    }

    // MARK: - Ruler

    /// The year interval between ruler ticks at the current zoom level.
    var tickStep: Int {
        Self.tickStepCandidates.first {
            CGFloat($0) * pointsPerYear >= Self.minTickSpacing
        } ?? Self.fallbackTickStep
    }

    /// Every ruler tick across the whole timeline range.
    ///
    /// Prefer ``visibleTicks`` for drawing, since this can be thousands of
    /// ticks when zoomed in.
    var ticks: [TimelineTick] {
        guard !entries.isEmpty else { return [] }
        return makeTicks(from: minYear, through: maxYear)
    }

    /// The ticks in the visible window plus one step of overscan on each side.
    ///
    /// Falls back to ``ticks`` until the viewport size is known.
    var visibleTicks: [TimelineTick] {
        guard !entries.isEmpty else { return [] }
        guard viewportSize.width > 0 else { return ticks }

        let step = tickStep
        let left = -offset.width - Self.horizontalPadding
        let right = left + viewportSize.width

        let firstYear = minYear + Int((left / pointsPerYear).rounded(.down)) - step
        let lastYear = minYear + Int((right / pointsPerYear).rounded(.up)) + step

        return makeTicks(
            from: max(minYear, firstYear),
            through: min(maxYear, lastYear)
        )
    }

    private func makeTicks(from lower: Int, through upper: Int) -> [TimelineTick] {
        let step = tickStep
        let first = Int((Double(lower) / Double(step)).rounded(.up)) * step

        return stride(from: first, through: upper, by: step)
            .map { TimelineTick(year: $0) }
    }

    // MARK: - Pan

    /// How far the canvas is shifted from its origin, kept within its bounds.
    var offset: CGSize {
        CGSize(
            width: min(0, max(viewportSize.width - totalWidth, storedOffset.width)),
            height: min(0, max(viewportSize.height - contentHeight, storedOffset.height))
        )
    }

    /// Pans while a drag gesture is in progress.
    func panChanged(_ translation: CGSize) {
        storedOffset = CGSize(
            width: offset.width + translation.width - lastPanTranslation.width,
            height: offset.height + translation.height - lastPanTranslation.height
        )

        lastPanTranslation = translation
    }

    /// Clears the stored drag translation when a drag ends.
    func panEnded() {
        lastPanTranslation = .zero
    }

    /// The range of years currently visible, for display.
    var visibleRangeText: String {
        func year(atContentX x: CGFloat) -> Int {
            let raw = minYear + Int(
                ((x - Self.horizontalPadding) / pointsPerYear).rounded()
            )

            return min(max(raw, minYear), maxYear)
        }

        let left = -offset.width

        return "\(TimelineEntry.label(for: year(atContentX: left))) – "
            + "\(TimelineEntry.label(for: year(atContentX: left + viewportSize.width)))"
    }

    // MARK: - Zoom

    /// Increases the scale.
    func zoomIn() {
        setScale(pointsPerYear * 1.5)
    }

    /// Decreases the scale.
    func zoomOut() {
        setScale(pointsPerYear / 1.5)
    }

    /// Scales the timeline so its whole year range fits the given width.
    ///
    /// - Parameter width: The available horizontal width.
    func fit(toWidth width: CGFloat) {
        let span = CGFloat(max(maxYear - minYear, 1))
        let available = width - Self.horizontalPadding * 2 - Self.minBarWidth

        guard available > 0 else { return }

        setScale(available / span)
        storedOffset = .zero
    }

    /// Updates the scale while a pinch is in progress.
    ///
    /// - Parameters:
    ///   - magnification: The pinch magnification since the gesture began.
    ///   - point: The pinch centre in canvas coordinates. It stays fixed.
    func pinchChanged(_ magnification: CGFloat, around point: CGPoint) {
        if pinchAnchor == nil {
            pinchAnchor = pointsPerYear
        }

        let yearsFromStart =
            (point.x - offset.width - Self.horizontalPadding) / pointsPerYear

        setScale((pinchAnchor ?? pointsPerYear) * magnification)

        storedOffset.width =
            point.x - Self.horizontalPadding - yearsFromStart * pointsPerYear
    }

    /// Clears the stored pinch anchor when a pinch ends.
    func pinchEnded() {
        pinchAnchor = nil
    }

    /// Zooms so an entry's lifespan fills the visible width.
    ///
    /// - Parameter entry: The entry to focus on.
    func zoom(to entry: TimelineEntry) {
        let available = viewportSize.width - Self.horizontalPadding * 2
        guard available > 0 else { return }

        pinchAnchor = nil
        setScale(available / CGFloat(max(entry.span, 1)))

        let barBottom = yOffset(for: entry) + Self.rowHeight + Self.rowSpacing

        storedOffset = CGSize(
            width: -CGFloat(entry.startYear - minYear) * pointsPerYear,
            height: min(0, viewportSize.height - barBottom)
        )
    }

    /// Restores the default zoom and scrolls back to the start.
    func reset() {
        pinchAnchor = nil
        setScale(Self.defaultScale)
        storedOffset = .zero
    }

    // MARK: - Hit Testing

    /// Returns the entry whose bar contains a point.
    ///
    /// - Parameter point: A location relative to the visible canvas.
    /// - Returns: The matching entry, or `nil` for empty space.
    func entry(at point: CGPoint) -> TimelineEntry? {
        let x = point.x - offset.width
        let y = point.y - offset.height

        return entries.first { entry in
            let originX = xOffset(for: entry)
            let originY = yOffset(for: entry)

            return x >= originX
                && x <= originX + width(for: entry)
                && y >= originY
                && y <= originY + Self.rowHeight
        }
    }

    // MARK: - Scale

    private func setScale(_ value: CGFloat) {
        let clamped = min(Self.maxScale, max(Self.minScale, value))
        guard clamped != pointsPerYear else { return }

        let layout = Self.packRows(entries, scale: clamped)
        pointsPerYear = clamped
        rowCount = layout.count
        rows = layout.rows
    }

    // MARK: - Row Packing

    /// Assigns each entry to the first row where it doesn't overlap.
    private static func packRows(
        _ entries: [TimelineEntry],
        scale: CGFloat
    ) -> (rows: [String: Int], count: Int) {
        var rowEnds: [CGFloat] = []
        var result: [String: Int] = [:]

        for entry in entries {
            let startX = CGFloat(entry.startYear) * scale
            let width = max(minBarWidth, CGFloat(entry.span) * scale)
            let endX = startX + width + barGap

            if let row = rowEnds.firstIndex(where: { $0 <= startX }) {
                result[entry.id] = row
                rowEnds[row] = endX
            } else {
                result[entry.id] = rowEnds.count
                rowEnds.append(endX)
            }
        }

        return (result, rowEnds.count)
    }
}
