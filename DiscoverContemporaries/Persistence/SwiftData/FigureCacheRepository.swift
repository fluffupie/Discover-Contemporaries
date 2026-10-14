import Foundation
import SwiftData

/// Manages historical figures stored in the local SwiftData cache.
///
/// Provides methods for fetching, inserting, updating, and deleting
/// historical figure records.
///
/// Uses `@MainActor` to ensure all repository operations are performed
/// on the main actor when accessing the SwiftData model context.
@MainActor
final class FigureCacheRepository {

    /// The default maximum age of a cached figure: seven days (expressed in seconds).
    static let defaultMaxAge: TimeInterval = 60 * 60 * 24 * 7

    /// The SwiftData model context used for database operations.
    private let context: ModelContext

    // MARK: - Initialization

    /// Creates a repository using the specified SwiftData model context.
    ///
    /// - Parameter context: The model context used for all cache read and write operations.
    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Fetch

    /// Returns a cached historical figure by its Wikidata ID and records it as recently viewed.
    ///
    /// - Parameter id: The Wikidata ID of the requested figure.
    /// - Returns: The historical figure, or `nil` if it is not cached.
    /// - Throws: An error if fetching or saving the record fails.
    func fetchFigure(withID id: String) throws -> HistoricalFigure? {
        guard let cached = try fetchCachedFigure(withID: id) else {
            return nil
        }

        cached.markAsViewed()
        try saveContext()

        return cached.historicalFigure
    }

    /// Returns a cached historical figure by ID without updating its recent-view timestamp.
    ///
    /// - Parameter id: The Wikidata ID of the requested figure.
    /// - Returns: The historical figure, or `nil` if it is not cached.
    /// - Throws: An error if the SwiftData fetch fails.
    func fetchFigureWithoutMarkingViewed(withID id: String) throws
        -> HistoricalFigure?
    {
        try fetchCachedFigure(withID: id)?.historicalFigure
    }

    /// Returns all cached historical figures sorted by name.
    ///
    /// - Returns: An array of cached historical figures, or an empty array if the cache contains no figures.
    /// - Throws: An error if the SwiftData fetch fails.
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
    ///
    /// - Parameter limit: The maximum number of figures to return. Defaults to `10`.
    /// - Returns: An array of recently viewed historical figures.
    /// - Throws: An error if the SwiftData fetch fails.
    func fetchRecentlyViewed(limit: Int = 10) throws -> [HistoricalFigure] {
        var descriptor = FetchDescriptor<CachedHistoricalFigure>(
            predicate: #Predicate { $0.lastViewedAt != nil },
            sortBy: [SortDescriptor(\.lastViewedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        return try context.fetch(descriptor).map(\.historicalFigure)
    }

    /// Retrieves cached historical figures matching the supplied Wikidata IDs.
    ///
    /// - Parameter ids: The Wikidata IDs of the requested figures.
    /// - Returns: An array of matching historical figures in the requested order.
    /// - Throws: An error if the SwiftData fetch fails.
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
    /// Inserts a historical figure or updates its existing cached record.
    ///
    /// - Parameter figure: The historical figure to cache.
    /// - Throws: An error if the fetch, insertion, or save fails.
    func save(_ figure: HistoricalFigure) throws {
        try CachedHistoricalFigure.upsert(figure, in: context)
        try saveContext()
    }

    /// Inserts or updates multiple historical figures in a single save operation.
    func saveAll(
        _ figures: [HistoricalFigure]
    ) throws {
        guard !figures.isEmpty else { return }
        
        /// Retrieves existing matching records before processing the figures and performs a single save operation.
        var cachedByID = Dictionary(
            try fetchCachedFigures(withIDs: figures.map(\.id)).map {
                ($0.wikidataID, $0)
            },
            uniquingKeysWith: { first, _ in first }
        )

        for figure in figures {
            if let cached = cachedByID[figure.id] {
                cached.update(from: figure)
            } else {
                let cached = CachedHistoricalFigure(from: figure)
                context.insert(cached)
                cachedByID[figure.id] = cached
            }
        }

        try context.save()
    }

    // MARK: - Cache State

    /// Checks whether a historical figure exists in the cache.
    ///
    /// - Parameter id: The Wikidata ID to search for.
    /// - Returns: `true` if the figure exists; otherwise, `false`.
    /// - Throws: An error if the count query fails.
    func containsFigure(withID id: String) throws -> Bool {
        let descriptor = FetchDescriptor<CachedHistoricalFigure>(
            predicate: #Predicate { $0.wikidataID == id }
        )

        return try context.fetchCount(descriptor) > 0
    }

    /// Checks whether the cache contains any historical figures.
    ///
    /// - Returns: `true` if at least one figure is cached;
    ///   otherwise, `false`.
    /// - Throws: An error if the SwiftData count query fails.
    func hasAnyFigures() throws -> Bool {
        try context.fetchCount(FetchDescriptor<CachedHistoricalFigure>()) > 0
    }

    /// Determines whether a cached figure is sufficiently recent.
    ///
    /// Compares the figure's cache timestamp against the specified maximum acceptable age.
    ///
    /// - Parameters:
    ///     - id: The Wikidata ID of the figure to check.
    ///     - maxAge: The maximum acceptable cache age, in seconds. Defaults to ``defaultMaxAge``.
    /// - Returns: `true` if the figure exists and its cache age does not exceed `maxAge`; otherwise, `false`.
    /// - Throws: An error if fetching the cached figure fails.
    func isCacheFresh(
        for id: String,
        maxAge: TimeInterval = FigureCacheRepository.defaultMaxAge
    ) throws -> Bool {
        guard let cached = try fetchCachedFigure(withID: id) else {
            return false
        }

        return !cached.isStale(olderThan: maxAge)
    }

    // MARK: - Delete

    /// Removes the historical figure with the specified ID from the cache.
    ///
    /// - Parameter id: The Wikidata ID of the figure to delete.
    /// - Throws: An error if fetching or saving the deletion fails.
    func deleteFigure(withID id: String) throws {
        guard let cached = try fetchCachedFigure(withID: id) else {
            return
        }

        context.delete(cached)
        try saveContext()
    }

    /// Removes all historical figures from the SwiftData cache.
    ///
    /// - Throws: An error if deleting or saving the records fails.
    func clearCache() throws {
        try context.delete(model: CachedHistoricalFigure.self)
        try saveContext()
    }

    // MARK: - Private Helpers

    /// Fetches the persistent cached record matching a Wikidata ID.
    ///
    /// Limits the query to a single result.
    ///
    /// - Parameter id: The Wikidata ID of the requested figure.
    /// - Returns: The cached SwiftData model, or `nil` if not found.
    /// - Throws: An error if the SwiftData fetch fails.
    private func fetchCachedFigure(withID id: String) throws
        -> CachedHistoricalFigure?
    {
        var descriptor = FetchDescriptor<CachedHistoricalFigure>(
            predicate: #Predicate { $0.wikidataID == id }
        )
        descriptor.fetchLimit = 1

        return try context.fetch(descriptor).first
    }
    
    /// Fetches persistent cached records matching multiple Wikidata IDs.
    ///
    /// - Parameter ids: The Wikidata IDs to retrieve.
    /// - Returns: An array of matching cached SwiftData models.
    /// - Throws: An error if the SwiftData fetch fails.
    private func fetchCachedFigures(withIDs ids: [String]) throws
        -> [CachedHistoricalFigure]
    {
        try context.fetch(
            FetchDescriptor<CachedHistoricalFigure>(
                predicate: #Predicate { ids.contains($0.wikidataID) }
            )
        )
    }

    /// Saves pending changes to the SwiftData model context.
    ///
    /// - Throws: The original error encountered during the save.
    private func saveContext() throws {
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
}
