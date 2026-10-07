import Foundation
import SwiftData

@MainActor
final class FigureCacheRepository {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Fetch

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

    func fetchFigureWithoutMarkingViewed(
        withID id: String
    ) throws -> HistoricalFigure? {
        try fetchCachedFigure(
            withID: id
        )?.historicalFigure
    }

    func fetchAllFigures() throws -> [HistoricalFigure] {
        let descriptor = FetchDescriptor<CachedHistoricalFigure>(
            sortBy: [
                SortDescriptor(\.name)
            ]
        )

        return try context.fetch(descriptor)
            .map(\.historicalFigure)
    }

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

    // MARK: - Save

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

    // MARK: - Cache State

    func containsFigure(
        withID id: String
    ) throws -> Bool {
        try fetchCachedFigure(withID: id) != nil
    }

    func hasAnyFigures() throws -> Bool {
        var descriptor = FetchDescriptor<CachedHistoricalFigure>()
        descriptor.fetchLimit = 1

        return try !context.fetch(descriptor).isEmpty
    }

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
