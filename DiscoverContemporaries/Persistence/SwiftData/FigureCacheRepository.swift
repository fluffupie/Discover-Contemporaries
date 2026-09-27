import Foundation
import SwiftData

@MainActor
final class FigureCacheRepository {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Fetch one cached figure
    func fetchFigure(withID id: String) throws -> HistoricalFigure? {
        let descriptor = FetchDescriptor<CachedHistoricalFigure>(
            predicate: #Predicate {
                $0.wikidataID == id
            }
        )

        guard let cachedFigure = try context.fetch(descriptor).first else {
            return nil
        }

        cachedFigure.lastViewedAt = Date()
        try context.save()

        return cachedFigure.toHistoricalFigure()
    }

    // MARK: - Save or update figure

    func save(_ figure: HistoricalFigure) throws {
        let id = figure.id

        let descriptor = FetchDescriptor<CachedHistoricalFigure>(
            predicate: #Predicate {
                $0.wikidataID == id
            }
        )

        if let existingFigure = try context.fetch(descriptor).first {
            update(existingFigure, using: figure)
        } else {
            let cachedFigure = CachedHistoricalFigure(from: figure)
            context.insert(cachedFigure)
        }

        try context.save()
    }

    // MARK: - Fetch all cached figures

    func fetchAllFigures() throws -> [HistoricalFigure] {
        let descriptor = FetchDescriptor<CachedHistoricalFigure>(
            sortBy: [
                SortDescriptor(\.name)
            ]
        )

        return try context.fetch(descriptor).map {
            $0.toHistoricalFigure()
        }
    }

    // MARK: - Fetch recently viewed figures

    func fetchRecentlyViewed(limit: Int = 10) throws -> [HistoricalFigure] {
        var descriptor = FetchDescriptor<CachedHistoricalFigure>(
            sortBy: [
                SortDescriptor(
                    \.lastViewedAt,
                    order: .reverse
                )
            ]
        )

        descriptor.fetchLimit = limit

        return try context.fetch(descriptor).map {
            $0.toHistoricalFigure()
        }
    }

    // MARK: - Check whether figure exists

    func containsFigure(withID id: String) throws -> Bool {
        let descriptor = FetchDescriptor<CachedHistoricalFigure>(
            predicate: #Predicate {
                $0.wikidataID == id
            }
        )

        return try context.fetchCount(descriptor) > 0
    }

    // MARK: - Delete one cached figure

    func deleteFigure(withID id: String) throws {
        let descriptor = FetchDescriptor<CachedHistoricalFigure>(
            predicate: #Predicate {
                $0.wikidataID == id
            }
        )

        guard let figure = try context.fetch(descriptor).first else {
            return
        }

        context.delete(figure)
        try context.save()
    }

    // MARK: - Delete entire cache

    func clearCache() throws {
        let descriptor = FetchDescriptor<CachedHistoricalFigure>()
        let figures = try context.fetch(descriptor)

        for figure in figures {
            context.delete(figure)
        }

        try context.save()
    }

    // MARK: - Cache freshness

    func isCacheFresh(
        for id: String,
        maxAge: TimeInterval = 60 * 60 * 24 * 7
    ) throws -> Bool {
        let descriptor = FetchDescriptor<CachedHistoricalFigure>(
            predicate: #Predicate {
                $0.wikidataID == id
            }
        )

        guard let cachedFigure = try context.fetch(descriptor).first else {
            return false
        }

        return Date().timeIntervalSince(cachedFigure.cachedAt) < maxAge
    }

    // MARK: - Private helpers

    private func update(
        _ cachedFigure: CachedHistoricalFigure,
        using figure: HistoricalFigure
    ) {
        cachedFigure.name = figure.name
        cachedFigure.descriptionText = figure.descriptionText
        cachedFigure.gender = figure.gender
        cachedFigure.birthDate = figure.birthDate
        cachedFigure.deathDate = figure.deathDate
        cachedFigure.country = figure.country
        cachedFigure.placeOfBirth = figure.placeOfBirth
        cachedFigure.imageURL = figure.imageURL?.absoluteString
        cachedFigure.occupations = figure.occupations
        cachedFigure.movements = figure.movements
        cachedFigure.cachedAt = Date()
        cachedFigure.lastViewedAt = Date()
    }

}
