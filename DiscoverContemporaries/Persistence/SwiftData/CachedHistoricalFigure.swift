import Foundation
import SwiftData

@Model
final class CachedHistoricalFigure {

    @Attribute(.unique)
    var wikidataID: String
    var name: String
    var descriptionText: String?
    var gender: String?

    var birthDate: Date?
    var deathDate: Date?
    
    var country: String?
    var placeOfBirth: String?
    var imageURL: String?
    var imageName: String?
    
    var occupations: [String]
    var movements: [String]

    var cachedAt: Date
    var lastViewedAt: Date

    init(
        wikidataID: String,
        name: String,
        descriptionText: String? = nil,
        gender: String? = nil,
        birthDate: Date? = nil,
        deathDate: Date? = nil,
        country: String? = nil,
        placeOfBirth: String? = nil,
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
        self.country = country
        self.placeOfBirth = placeOfBirth
        self.imageURL = imageURL
        self.imageName = imageName
        self.occupations = occupations
        self.movements = movements
        self.cachedAt = Date()
        self.lastViewedAt = Date()
    }
}

extension CachedHistoricalFigure {

    convenience init(from figure: HistoricalFigure) {
        self.init(
            wikidataID: figure.id,
            name: figure.name,
            descriptionText: figure.descriptionText,
            gender: figure.gender,
            
            birthDate: figure.birthDate,
            deathDate: figure.deathDate,
            
            country: figure.country,
            placeOfBirth: figure.placeOfBirth,
            
            imageURL: figure.imageURL?.absoluteString,
            imageName: figure.imageName,
            occupations: figure.occupations,
            movements: figure.movements
        )
    }

    func toHistoricalFigure() -> HistoricalFigure {
        HistoricalFigure(
            id: wikidataID,
            name: name,
            descriptionText: descriptionText,
            gender: gender,
            
            birthDate: birthDate,
            deathDate: deathDate,
            
            country: country,
            placeOfBirth: placeOfBirth,
            occupations: occupations,
            movements: movements,
            imageURL: imageURL.flatMap { URL(string: $0) },
            imageName: imageName
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
