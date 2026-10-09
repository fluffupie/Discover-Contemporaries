import Combine
import CoreGraphics
import Foundation

/// Manages timeline layout, selection, ruler generation, and zoom state for historical figures.
@MainActor
final class TimelineViewModel: ObservableObject {

    // Layout constants
    static let minScale: CGFloat = 0.1
    static let maxScale: CGFloat = 40
    static let rowHeight: CGFloat = 34
    static let rowSpacing: CGFloat = 6
    static let rulerHeight: CGFloat = 26
    static let minBarWidth: CGFloat = 56
    static let barGap: CGFloat = 6
    static let horizontalPadding: CGFloat = 24

    // Data
    let entries: [TimelineEntry]
    let skippedCount: Int
    let highlightedID: String?

    // State
    @Published private(set) var pointsPerYear: CGFloat = 4
    @Published private(set) var rows: [String: Int] = [:]
    @Published var selectedID: String?

    private var pinchAnchor: CGFloat?

    // Init

    /// Creates timeline entries from historical figures and prepares their initial row layout.
    ///
    /// Duplicate figures are removed, figures without usable timeline dates are skipped,
    /// and the remaining entries are ordered by starting year.
    ///
    /// - Parameters:
    ///   - figures: The historical figures to display on the timeline.
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

        self.entries = built
        self.skippedCount = unique.count - built.count
        self.highlightedID = highlightedID
        self.selectedID = highlightedID
        self.rows = Self.packRows(built, scale: 4)
    }

    // Range

    /// The earliest starting year represented on the timeline.
    var minYear: Int {
        entries.map(\.startYear).min() ?? 0
    }

    /// The latest ending year represented on the timeline.
    var maxYear: Int {
        entries.map(\.endYear).max() ?? 1
    }

    /// The currently selected timeline entry, if one exists.
    var selectedEntry: TimelineEntry? {
        entries.first { $0.id == selectedID }
    }

    // Geometry

    /// The number of rows required to display timeline bars without overlap.
    var rowCount: Int {
        (rows.values.max() ?? -1) + 1
    }

    /// The total horizontal width required for the current timeline scale.
    var totalWidth: CGFloat {
        CGFloat(maxYear - minYear) * pointsPerYear
        + Self.horizontalPadding * 2
        + Self.minBarWidth
    }

    /// The total vertical height required for the current row layout.
    var contentHeight: CGFloat {
        Self.rulerHeight
        + CGFloat(rowCount) * (Self.rowHeight + Self.rowSpacing)
        + 16
    }

    /// Returns the horizontal position for a specific year.
    ///
    /// - Parameter year: The year to position on the timeline.
    /// - Returns: The horizontal offset in points.
    func xOffset(forYear year: Int) -> CGFloat {
        Self.horizontalPadding
        + CGFloat(year - minYear) * pointsPerYear
    }

    /// Returns the horizontal position for a timeline entry.
    ///
    /// - Parameter entry: The timeline entry to position.
    /// - Returns: The horizontal offset in points.
    func xOffset(for entry: TimelineEntry) -> CGFloat {
        xOffset(forYear: entry.startYear)
    }

    /// Returns the displayed width of a timeline entry.
    ///
    /// - Parameter entry: The timeline entry whose bar width should be calculated.
    /// - Returns: The width of the timeline bar in points.
    func width(for entry: TimelineEntry) -> CGFloat {
        max(Self.minBarWidth, CGFloat(entry.span) * pointsPerYear)
    }

    /// Returns the vertical position of a timeline entry based on its assigned row.
    ///
    /// - Parameter entry: The timeline entry to position.
    /// - Returns: The vertical offset in points.
    func yOffset(for entry: TimelineEntry) -> CGFloat {
        let row = rows[entry.id] ?? 0

        return Self.rulerHeight
        + CGFloat(row) * (Self.rowHeight + Self.rowSpacing)
    }

    // Ruler

    /// The year interval used between timeline ruler ticks at the current zoom level.
    var tickStep: Int {
        let candidates = [1, 2, 5, 10, 25, 50, 100, 250, 500, 1000, 2500]

        return candidates.first {
            CGFloat($0) * pointsPerYear >= 70
        } ?? 5000
    }

    /// The ruler ticks visible across the current timeline range.
    var ticks: [TimelineTick] {
        guard !entries.isEmpty else {
            return []
        }

        let step = tickStep

        var year =
            Int(
                (Double(minYear) / Double(step))
                    .rounded(.down)
            ) * step

        var result: [TimelineTick] = []

        while year <= maxYear {
            if year >= minYear {
                result.append(
                    TimelineTick(year: year)
                )
            }

            year += step
        }

        return result
    }

    // Selection

    /// Selects a timeline entry or deselects it when it is already selected.
    ///
    /// - Parameter entry: The timeline entry whose selection state should change.
    func select(_ entry: TimelineEntry) {
        selectedID =
            selectedID == entry.id
            ? nil
            : entry.id
    }

    // Zoom

    /// Increases the timeline scale.
    func zoomIn() {
        setScale(pointsPerYear * 1.5)
    }

    /// Decreases the timeline scale.
    func zoomOut() {
        setScale(pointsPerYear / 1.5)
    }

    /// Adjusts the timeline scale so its year range fits within the supplied width.
    ///
    /// - Parameter width: The available horizontal width for the timeline.
    func fit(toWidth width: CGFloat) {
        let span =
            CGFloat(
                max(
                    maxYear - minYear,
                    1
                )
            )

        let available =
            width
            - Self.horizontalPadding * 2
            - Self.minBarWidth

        guard available > 0 else {
            return
        }

        setScale(
            available / span
        )
    }

    /// Updates the timeline scale while a pinch gesture is in progress.
    ///
    /// - Parameter magnification: The current pinch magnification value.
    func pinchChanged(
        _ magnification: CGFloat
    ) {
        if pinchAnchor == nil {
            pinchAnchor = pointsPerYear
        }

        setScale(
            (pinchAnchor ?? pointsPerYear)
            * magnification
        )
    }

    /// Clears the stored pinch anchor when a pinch gesture ends.
    func pinchEnded() {
        pinchAnchor = nil
    }

    private func setScale(
        _ value: CGFloat
    ) {
        let clamped =
            min(
                Self.maxScale,
                max(
                    Self.minScale,
                    value
                )
            )

        guard clamped != pointsPerYear else {
            return
        }

        pointsPerYear = clamped
        rows = Self.packRows(
            entries,
            scale: clamped
        )
    }

    // Row Packing

    private static func packRows(
        _ entries: [TimelineEntry],
        scale: CGFloat
    ) -> [String: Int] {
        var rowEnds: [CGFloat] = []
        var result: [String: Int] = [:]

        for entry in entries {
            let startX =
                CGFloat(entry.startYear)
                * scale

            let width =
                max(
                    minBarWidth,
                    CGFloat(entry.span) * scale
                )

            let endX =
                startX
                + width
                + barGap

            if let row = rowEnds.firstIndex(
                where: {
                    $0 <= startX
                }
            ) {
                result[entry.id] = row
                rowEnds[row] = endX
            } else {
                result[entry.id] =
                    rowEnds.count

                rowEnds.append(
                    endX
                )
            }
        }

        return result
    }
}
