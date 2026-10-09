//
//  TimelineEntry.swift
//  a1
//
//  Created by Hengly Lim on 6/10/2026.
//

import Foundation


/// Model for timeline
struct  TimelineEntry: Identifiable {
    let figure: HistoricalFigure
    let startYear: Int
    let endYear: Int
    let isLiving: Bool

    var id: String { figure.id }

    // Length of life in years (never less than 1).
    var span: Int { max(endYear - startYear, 1) }

    var yearRangeText: String {
        let end = isLiving ? "Present" : Self.label(for: endYear)
        return "\(Self.label(for: startYear)) – \(end)"
    }

    // Returns nil when the figure has no birth date
    // or when the date range is invalid.
    init?(figure: HistoricalFigure) {
        guard let birth = figure.birthDate else {
            return nil
        }

        let start = Self.year(from: birth)
        let end = figure.deathDate.map(Self.year(from:)) ?? Self.currentYear

        guard end >= start else {
            return nil
        }

        self.figure = figure
        self.startYear = start
        self.endYear = end
        self.isLiving = figure.deathDate == nil
    }

    // Year Helpers
    private static let calendar = Calendar(identifier: .gregorian)

    static var currentYear: Int {
        calendar.component(.year, from: Date())
    }

    // Convert a date to a signed year: 1 BC = 0, 2 BC = -1, etc
    static func year(from date: Date) -> Int {
        let components = calendar.dateComponents([.era, .year], from: date)
        let year = components.year ?? 0
        return components.era == 0 ? 1 - year : year
    }

    // "1452" for AD years, "500 BC" for years <= 0.
    static func label(for year: Int) -> String {
        year <= 0 ? "\(1 - year) BC" : "\(year)"
    }
}

// A labelled mark on the year ruler.
struct TimelineTick: Identifiable {
    let year: Int

    var id: Int { year }
    var label: String { TimelineEntry.label(for: year) }
}
