import Foundation


/// Model for contemporary figure
struct ContemporaryFigure: Identifiable {
    let id: String
    let name: String
    let birthDate: Date?
    let deathDate: Date?
    let imageURL: URL?

    // MARK: - Conversion
    var historicalFigure: HistoricalFigure {
        HistoricalFigure(
            id: id,
            name: name,
            descriptionText: nil,
            gender: nil,
            birthPlace: nil,
            birthDate: birthDate,
            deathDate: deathDate,
            occupations: [],
            movements: [],
            imageURL: imageURL,
            imageName: nil
        )
    }

    // MARK: - Display Values
    var lifespanText: String {
        historicalFigure.lifespan
    }
}
