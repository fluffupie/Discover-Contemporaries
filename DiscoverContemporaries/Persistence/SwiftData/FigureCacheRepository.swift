import Foundation
import SwiftData

@MainActor
final class FigureCacheRepository {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func save(_ figure: HistoricalFigure) throws {

        let id = figure.id

        let descriptor = FetchDescriptor<CachedHistoricalFigure>(
            predicate: #Predicate {
                $0.wikidataID == id
            }
        )

        if let existing = try context.fetch(descriptor).first {

            existing.name = figure.name
            existing.birthDate = figure.birthDate
            existing.deathDate = figure.deathDate
            existing.descriptionText = figure.description
            existing.region = figure.region
            existing.imageURL = figure.imageURL?.absoluteString

            existing.cachedAt = Date()
            existing.lastViewedAt = Date()

        } else {

            let cachedFigure = CachedHistoricalFigure(
                wikidataID: figure.id,
                name: figure.name,
                birthDate: figure.birthDate,
                deathDate: figure.deathDate,
                descriptionText: figure.description,
                region: figure.region,
                imageURL: figure.imageURL?.absoluteString
            )

            context.insert(cachedFigure)
        }

        try context.save()
    }
}
