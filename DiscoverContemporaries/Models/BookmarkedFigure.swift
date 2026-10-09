import Foundation

/// Model for bookmarked figure
struct BookmarkedFigure: Codable, Identifiable {
    let id: String
    let name: String
    let descriptionText: String?
    let birthDate: Date?
    let deathDate: Date?
    let imageURL: URL?
    let imageName: String?

    init(
        id: String,
        name: String,
        descriptionText: String?,
        birthDate: Date?,
        deathDate: Date?,
        imageURL: URL?,
        imageName: String?
    ) {
        self.id = id
        self.name = name
        self.descriptionText = descriptionText
        self.birthDate = birthDate
        self.deathDate = deathDate
        self.imageURL = imageURL
        self.imageName = imageName
    }

    init(from figure: HistoricalFigure) {
        self.init(
            id: figure.id,
            name: figure.name,
            descriptionText: figure.descriptionText,
            birthDate: figure.birthDate,
            deathDate: figure.deathDate,
            imageURL: figure.imageURL,
            imageName: figure.imageName
        )
    }
}

// MARK: - Historical Figure Conversion

extension BookmarkedFigure {
    var historicalFigure: HistoricalFigure {
        HistoricalFigure(
            id: id,
            name: name,
            descriptionText: descriptionText,
            gender: nil,
            birthPlace: nil,
            birthDate: birthDate,
            deathDate: deathDate,
            occupations: [],
            movements: [],
            imageURL: imageURL,
            imageName: imageName
        )
    }
}
