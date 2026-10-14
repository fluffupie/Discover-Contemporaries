import Foundation
import SwiftData

/// A historical figure stored in the local SwiftData cache.
@Model
final class CachedHistoricalFigure {

    /// The `.unique` attribute prevents duplicate cached records with the same Wikidata ID.
    @Attribute(.unique)
    var wikidataID: String

    var name: String
    var descriptionText: String?
    var gender: String?

    var birthDate: Date?
    var deathDate: Date?

    var birthPlace: String?
    var imageURL: String?
    var imageName: String?

    var occupations: [String]
    var movements: [String]

    /// The date and time when the cached record was created or last refreshed.
    var cachedAt: Date
    
    /// The date and time when the figure was last viewed. A `nil` value indicates that no view has been recorded.
    var lastViewedAt: Date?

    // MARK: - Initialisation
    
    /// Creates a cached historical figure with the specified information.
    init(
        wikidataID: String,
        name: String,
        descriptionText: String? = nil,
        gender: String? = nil,
        birthDate: Date? = nil,
        deathDate: Date? = nil,
        birthPlace: String? = nil,
        imageURL: String? = nil,
        imageName: String? = nil,
        occupations: [String] = [],
        movements: [String] = [],
        cachedAt: Date = .now,
        lastViewedAt: Date? = nil
    ) {
        self.wikidataID = wikidataID
        self.name = name
        self.descriptionText = descriptionText
        self.gender = gender
        self.birthDate = birthDate
        self.deathDate = deathDate
        self.birthPlace = birthPlace
        self.imageURL = imageURL
        self.imageName = imageName
        self.occupations = occupations
        self.movements = movements
        self.cachedAt = cachedAt
        self.lastViewedAt = lastViewedAt
    }
}

// MARK: - Historical Figure Conversion

extension CachedHistoricalFigure {

    /// Creates a cached historical figure from a domain model.
    /// - Parameter figure: The historical figure to cache.
    convenience init(from figure: HistoricalFigure) {
        self.init(
            wikidataID: figure.id,
            name: figure.name,
            descriptionText: figure.descriptionText,
            gender: figure.gender,
            birthDate: figure.birthDate,
            deathDate: figure.deathDate,
            birthPlace: figure.birthPlace,
            imageURL: figure.imageURL?.absoluteString,
            imageName: figure.imageName,
            occupations: figure.occupations,
            movements: figure.movements
        )
    }

    /// Converts the cached record into a `HistoricalFigure` domain model.
    var historicalFigure: HistoricalFigure {
        HistoricalFigure(
            id: wikidataID,
            name: name,
            descriptionText: descriptionText,
            gender: gender,
            birthPlace: birthPlace,
            birthDate: birthDate,
            deathDate: deathDate,
            occupations: occupations,
            movements: movements,
            imageURL: imageURL.flatMap(URL.init(string:)),
            imageName: imageName
        )
    }
}

// MARK: - Updating

extension CachedHistoricalFigure {

    /// Updates the cached record with the latest historical figure data.
    /// - Parameter figure: The historical figure containing updated data.
    func update(from figure: HistoricalFigure) {
        assert(
            figure.id == wikidataID,
            "Updating \(wikidataID) with data for \(figure.id)"
        )
        name = figure.name
        descriptionText = figure.descriptionText
        gender = figure.gender
        birthDate = figure.birthDate
        deathDate = figure.deathDate
        birthPlace = figure.birthPlace
        imageURL = figure.imageURL?.absoluteString
        imageName = figure.imageName
        occupations = figure.occupations
        movements = figure.movements
        cachedAt = .now
    }

    /// Records the current time as the figure's most recent view.
    func markAsViewed() {
        lastViewedAt = .now
    }
    
    /// Determines whether the cached record is older than a given interval.
    ///
    /// - Parameters:
    ///   - interval: The maximum acceptable age, in seconds.
    ///   - now: The reference time used for comparison.
    func isStale(olderThan interval: TimeInterval, now: Date = .now) -> Bool {
        now.timeIntervalSince(cachedAt) > interval
    }
}

// MARK: - Upserting

extension CachedHistoricalFigure {
    /// Inserts a historical figure into the cache or updates an existing record.
    ///
    /// Searches SwiftData for an entry with the same Wikidata ID.
        /// If an entry exists, its information is refreshed using
        /// ``update(from:)``.
    ///
    /// - Parameters:
        ///   - figure: The historical figure to insert or update.
        ///   - context: The SwiftData model context used to fetch and insert cached records.
    ///
    /// - Returns: The existing updated record or the newly inserted cached record.
    @discardableResult
    static func upsert(
        _ figure: HistoricalFigure,
        in context: ModelContext
    ) throws -> CachedHistoricalFigure {
        let id = figure.id
        var descriptor = FetchDescriptor<CachedHistoricalFigure>(
            predicate: #Predicate { $0.wikidataID == id }
        )
        descriptor.fetchLimit = 1

        if let existing = try context.fetch(descriptor).first {
            existing.update(from: figure)
            return existing
        }

        let cached = CachedHistoricalFigure(from: figure)
        context.insert(cached)
        return cached
    }
}
