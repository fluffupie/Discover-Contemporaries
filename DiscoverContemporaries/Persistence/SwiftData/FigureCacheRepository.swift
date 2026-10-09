import Foundation
import SwiftData

/// Manages reading, writing, and maintaining historical figures in the SwiftData cache.
@MainActor
final class FigureCacheRepository {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Fetch
    /// Returns a cached figure by ID and records it as recently viewed.
    func fetchFigure(
        withID id: String
    ) throws -> HistoricalFigure? {
        guard let cachedFigure = try fetchCachedFigure(
            withID: id
        ) else {
            return nil
        }

        cachedFigure.markAsViewed()
        try context.save()

        return cachedFigure.historicalFigure
    }

    /// Returns a cached figure by ID without updating its recent-view timestamp.
    func fetchFigureWithoutMarkingViewed(
        withID id: String
    ) throws -> HistoricalFigure? {
        try fetchCachedFigure(
            withID: id
        )?.historicalFigure
    }

    /// Returns all cached historical figures sorted by name.
    func fetchAllFigures() throws -> [HistoricalFigure] {
        let descriptor = FetchDescriptor<CachedHistoricalFigure>(
            sortBy: [
                SortDescriptor(\.name)
            ]
        )

        return try context.fetch(descriptor)
            .map(\.historicalFigure)
    }

    /// Returns the most recently viewed historical figures.
    func fetchRecentlyViewed(
        limit: Int = 10
    ) throws -> [HistoricalFigure] {
        var descriptor = FetchDescriptor<CachedHistoricalFigure>(
            predicate: #Predicate {
                $0.lastViewedAt != nil
            },
            sortBy: [
                SortDescriptor(
                    \.lastViewedAt,
                    order: .reverse
                )
            ]
        )

        descriptor.fetchLimit = limit

        return try context.fetch(descriptor)
            .map(\.historicalFigure)
    }
    
    /// Returns cached historical figures matching the supplied IDs in the same order.
    func fetchFigures(
        withIDs ids: [String]
    ) throws -> [HistoricalFigure] {
        let cachedFigures = try context.fetch(
            FetchDescriptor<CachedHistoricalFigure>()
        )

        let figuresByID = Dictionary(
            uniqueKeysWithValues: cachedFigures.map {
                ($0.wikidataID, $0.historicalFigure)
            }
        )

        return ids.compactMap {
            figuresByID[$0]
        }
    }

    // MARK: - Save
    /// Inserts or updates a historical figure in the cache.
    func save(_ figure: HistoricalFigure) throws {
        if let existingFigure = try fetchCachedFigure(
            withID: figure.id
        ) {
            existingFigure.update(from: figure)
        } else {
            context.insert(
                CachedHistoricalFigure(from: figure)
            )
        }

        try context.save()
    }
    
    /// Inserts or updates multiple historical figures in a single save operation.
    func saveAll(
        _ figures: [HistoricalFigure]
    ) throws {
        for figure in figures {
            if let existingFigure = try fetchCachedFigure(
                withID: figure.id
            ) {
                existingFigure.update(from: figure)
            } else {
                context.insert(
                    CachedHistoricalFigure(from: figure)
                )
            }
        }

        try context.save()
    }

    // MARK: - Cache State
    /// Returns whether a figure with the specified ID exists in the cache.
    func containsFigure(
        withID id: String
    ) throws -> Bool {
        try fetchCachedFigure(withID: id) != nil
    }

    /// Returns whether the cache contains at least one historical figure.
    func hasAnyFigures() throws -> Bool {
        var descriptor = FetchDescriptor<CachedHistoricalFigure>()
        descriptor.fetchLimit = 1

        return try !context.fetch(descriptor).isEmpty
    }

    /// Returns whether the cached figure is newer than the specified maximum age.
    func isCacheFresh(
        for id: String,
        maxAge: TimeInterval = 60 * 60 * 24 * 7
    ) throws -> Bool {
        guard let cachedFigure = try fetchCachedFigure(
            withID: id
        ) else {
            return false
        }

        return Date().timeIntervalSince(
            cachedFigure.cachedAt
        ) < maxAge
    }

    // MARK: - Delete
    /// Removes the historical figure with the specified ID from the cache.
    func deleteFigure(
        withID id: String
    ) throws {
        guard let cachedFigure = try fetchCachedFigure(
            withID: id
        ) else {
            return
        }

        context.delete(cachedFigure)
        try context.save()
    }

    /// Removes all historical figures from the cache.
    func clearCache() throws {
        let descriptor = FetchDescriptor<CachedHistoricalFigure>()
        let figures = try context.fetch(descriptor)

        for figure in figures {
            context.delete(figure)
        }

        try context.save()
    }

    // MARK: - Private Helpers
    private func fetchCachedFigure(
        withID id: String
    ) throws -> CachedHistoricalFigure? {
        var descriptor = FetchDescriptor<CachedHistoricalFigure>(
            predicate: #Predicate {
                $0.wikidataID == id
            }
        )

        descriptor.fetchLimit = 1

        return try context.fetch(descriptor).first
    }
}
