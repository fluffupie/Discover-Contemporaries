import Foundation
import SwiftData

@Model
final class CachedHistoricalFigure {

    @Attribute(.unique)
    var wikidataID: String

    var name: String
    var birthDate: Date?
    var deathDate: Date?
    var descriptionText: String?
    var region: String?
    var imageURL: String?

    var cachedAt: Date
    var lastViewedAt: Date

    init(
        wikidataID: String,
        name: String,
        birthDate: Date? = nil,
        deathDate: Date? = nil,
        descriptionText: String? = nil,
        region: String? = nil,
        imageURL: String? = nil
    ) {
        self.wikidataID = wikidataID
        self.name = name
        self.birthDate = birthDate
        self.deathDate = deathDate
        self.descriptionText = descriptionText
        self.region = region
        self.imageURL = imageURL

        self.cachedAt = Date()
        self.lastViewedAt = Date()
    }
}

extension CachedHistoricalFigure {

    convenience init(from figure: HistoricalFigure) {
        self.init(
            wikidataID: figure.id,
            name: figure.name,
            birthDate: figure.birthDate,
            deathDate: figure.deathDate,
            descriptionText: figure.description,
            region: figure.region,
            imageURL: figure.imageURL?.absoluteString
        )
    }

    func toHistoricalFigure() -> HistoricalFigure {
        HistoricalFigure(
            id: wikidataID,
            name: name,
            description: descriptionText,
            birthDate: birthDate,
            deathDate: deathDate,
            region: region,
            imageURL: imageURL.flatMap { URL(string: $0) }
        )
    }
}

//https://www.wikidata.org/w/api.php
//?action=wbsearchentities
//&search=Napoleon
//&language=en
//&format=json
//&type=item
//&limit=10
