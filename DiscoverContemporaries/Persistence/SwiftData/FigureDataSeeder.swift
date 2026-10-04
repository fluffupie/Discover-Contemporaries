import Foundation
import SwiftData

@MainActor
enum FigureDataSeeder {

    static func seedIfNeeded(context: ModelContext) throws {
        let repository = FigureCacheRepository(context: context)

        guard try repository.fetchAllFigures().isEmpty else {
            return
        }

        let seedData = try loadSeedData()

        for seedFigure in seedData.figures {
            try repository.save(seedFigure.toHistoricalFigure())
        }
    }

    private static func loadSeedData() throws -> FigureSeedData {
        guard
            let url = Bundle.main.url(
                forResource: "FiguresData",
                withExtension: "json"
            )
        else {
            throw SeedError.missingFiguresData
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(FigureSeedData.self, from: data)
    }

    private enum SeedError: Error {
        case missingFiguresData
    }

    // MARK: - Seed Models
    private struct FigureSeedData: Decodable {
        let figures: [FigureSeed]
    }

    private struct FigureSeed: Decodable {
        let id: String
        let name: String
        let descriptionText: String?
        let gender: String?
        let birthDate: String?
        let deathDate: String?
        let birthPlace: String?
        let occupations: [String]
        let movements: [String]
        let imageURL: String?
        let imageName: String?

        func toHistoricalFigure() -> HistoricalFigure {
            HistoricalFigure(
                id: id,
                name: name,
                descriptionText: descriptionText,
                gender: gender,
                birthPlace: birthPlace,
                birthDate: Self.parseDate(birthDate),
                deathDate: Self.parseDate(deathDate),
                occupations: occupations,
                movements: movements,
                imageURL: Self.parseURL(imageURL),
                imageName: imageName
            )
        }

        private static func parseDate(_ text: String?) -> Date? {
            guard let text, !text.isEmpty else {
                return nil
            }

            return dateFormatter.date(from: text)
        }

        private static func parseURL(_ text: String?) -> URL? {
            guard let text, !text.isEmpty else {
                return nil
            }

            return URL(string: text)
        }

        private static let dateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter
        }()
    }
}
