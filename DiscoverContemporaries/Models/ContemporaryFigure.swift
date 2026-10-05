import Foundation

struct ContemporaryFigure: Identifiable {
    let id: String
    let name: String
    let birthDate: Date?
    let deathDate: Date?

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
            imageURL: nil,
            imageName: nil
        )
    }
    var lifespanText: String {
            historicalFigure.lifespan
        }
}
