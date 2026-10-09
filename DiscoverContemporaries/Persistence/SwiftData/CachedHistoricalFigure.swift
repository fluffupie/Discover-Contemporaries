import Foundation
import SwiftData

/// Stores a historical figure in the local SwiftData cache.
@Model
final class CachedHistoricalFigure {

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

    var cachedAt: Date
    var lastViewedAt: Date?

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
        movements: [String] = []
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
        self.cachedAt = Date()
        self.lastViewedAt = nil
    }
}

// MARK: - Historical Figure Conversion

extension CachedHistoricalFigure {
    
    /// Creates a cached historical figure from a domain model.
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
    
    /// Converts the cached model into a historical figure.
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

    /// Updates the cached values using the latest historical figure data.
    func update(from figure: HistoricalFigure) {
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
        cachedAt = Date()
    }

    /// Records the current time as the figure's most recent view date.
    func markAsViewed() {
        lastViewedAt = Date()
    }
}
