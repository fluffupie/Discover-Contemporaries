//  TimelineViewModel.swift
//  a1
//
//  Created by Lee Lim on 26/9/2026.
//

import Combine
import CoreGraphics
import Foundation

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
    var minYear: Int {
        entries.map(\.startYear).min() ?? 0
    }

    var maxYear: Int {
        entries.map(\.endYear).max() ?? 1
    }

    var selectedEntry: TimelineEntry? {
        entries.first { $0.id == selectedID }
    }

    // Geometry
    var rowCount: Int {
        (rows.values.max() ?? -1) + 1
    }

    var totalWidth: CGFloat {
        CGFloat(maxYear - minYear) * pointsPerYear
        + Self.horizontalPadding * 2
        + Self.minBarWidth
    }

    var contentHeight: CGFloat {
        Self.rulerHeight
        + CGFloat(rowCount) * (Self.rowHeight + Self.rowSpacing)
        + 16
    }

    func xOffset(forYear year: Int) -> CGFloat {
        Self.horizontalPadding
        + CGFloat(year - minYear) * pointsPerYear
    }

    func xOffset(for entry: TimelineEntry) -> CGFloat {
        xOffset(forYear: entry.startYear)
    }

    func width(for entry: TimelineEntry) -> CGFloat {
        max(Self.minBarWidth, CGFloat(entry.span) * pointsPerYear)
    }

    func yOffset(for entry: TimelineEntry) -> CGFloat {
        let row = rows[entry.id] ?? 0
        return Self.rulerHeight
        + CGFloat(row) * (Self.rowHeight + Self.rowSpacing)
    }

    // Ruler
    var tickStep: Int {
        let candidates = [1, 2, 5, 10, 25, 50, 100, 250, 500, 1000, 2500]
        return candidates.first { CGFloat($0) * pointsPerYear >= 70 } ?? 5000
    }

    var ticks: [TimelineTick] {
        guard !entries.isEmpty else {
            return []
        }

        let step = tickStep
        var year = Int((Double(minYear) / Double(step)).rounded(.down)) * step
        var result: [TimelineTick] = []

        while year <= maxYear {
            if year >= minYear {
                result.append(TimelineTick(year: year))
            }
            year += step
        }

        return result
    }

    // Selection
    func select(_ entry: TimelineEntry) {
        selectedID = selectedID == entry.id ? nil : entry.id
    }

    // Zoom
    func zoomIn() {
        setScale(pointsPerYear * 1.5)
    }

    func zoomOut() {
        setScale(pointsPerYear / 1.5)
    }

    func fit(toWidth width: CGFloat) {
        let span = CGFloat(max(maxYear - minYear, 1))
        let available = width
        - Self.horizontalPadding * 2
        - Self.minBarWidth

        guard available > 0 else {
            return
        }

        setScale(available / span)
    }

    func pinchChanged(_ magnification: CGFloat) {
        if pinchAnchor == nil {
            pinchAnchor = pointsPerYear
        }
        setScale((pinchAnchor ?? pointsPerYear) * magnification)
    }

    func pinchEnded() {
        pinchAnchor = nil
    }

    private func setScale(_ value: CGFloat) {
        let clamped = min(Self.maxScale, max(Self.minScale, value))
        guard clamped != pointsPerYear else {
            return
        }
        pointsPerYear = clamped
        rows = Self.packRows(entries, scale: clamped)
    }

    // Row Packing
    private static func packRows(
        _ entries: [TimelineEntry],
        scale: CGFloat
    ) -> [String: Int] {
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

        return result
    }
}
