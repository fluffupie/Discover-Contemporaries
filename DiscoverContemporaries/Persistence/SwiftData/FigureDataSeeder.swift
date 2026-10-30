import Foundation
import OSLog
import SwiftData

/// Seeds the local SwiftData cache with bundled historical figures.
///
/// Uses `@MainActor` to ensure SwiftData operations are performed on the main actor.
@MainActor
enum FigureDataSeeder {
    
    // MARK: - Seeding
    
    /// Inserts bundled historical figures that are not already cached.
    ///
    /// - Parameters:
    ///   - context: The SwiftData model context used for cache operations.
    ///   - bundle: The bundle containing `FiguresData.json`. Defaults to the main bundle.
    /// - Throws: ``SeedError/missingFiguresData`` if the file is absent, a decoding error if it's malformed, or a SwiftData error if saving fails.
    static func seedIfNeeded(
        context: ModelContext,
        bundle: Bundle = .main // Injecting the bundle
        // This supports loading the bundled data normally while allowing tests to supply another bundle.
    ) throws {
        let seeds = try loadSeedData(from: bundle).figures
        guard !seeds.isEmpty else { return }

        let repository = FigureCacheRepository(context: context)
        let existingIDs = Set(
            try repository.fetchFigures(withIDs: seeds.map(\.id)).map(\.id)
        )

        let dateFormatter = makeDateFormatter()
        let missing =
            seeds
            .filter { !existingIDs.contains($0.id) }
            .map { $0.historicalFigure(dateFormatter: dateFormatter) }

        try repository.saveAll(missing) // Batch saving
    }

    // MARK: - Loading
    
    /// Loads and decodes the bundled historical figure seed data.
    ///
    /// - Parameter bundle: The bundle containing the seed data file.
    /// - Returns: The decoded historical figure seed data.
    /// - Throws: ``SeedError/missingFiguresData`` if the file cannot be found, or an error if reading or decoding fails.
    private static func loadSeedData(from bundle: Bundle) throws
        -> FigureSeedData
    {
        guard
            let url = bundle.url(
                forResource: "FiguresData",
                withExtension: "json"
            )
        else {
            throw SeedError.missingFiguresData
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(FigureSeedData.self, from: data)
    }

    /// Parses `yyyy-MM-dd` strings on the Gregorian calendar.
    ///
    /// - Returns: A configured date formatter for parsing seed dates.
    private static func makeDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        
        formatter.isLenient = false // Lenient parsing is disabled to reduce acceptance of malformed date values.
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }

    // MARK: - Errors

    /// Errors thrown while seeding.
    enum SeedError: LocalizedError {
        
        /// Indicates that `FiguresData.json` was not found in the bundle
        case missingFiguresData

        var errorDescription: String? {
            switch self {
            case .missingFiguresData:
                String(
                    localized:
                        "FiguresData.json could not be found in the app bundle."
                )
            }
        }
    }
    
    /// Represents a single historical figure record in the seed file.
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
        let occupations: [String]?
        let movements: [String]?
        let imageURL: String?
        let imageName: String?

        func historicalFigure(dateFormatter: DateFormatter) -> HistoricalFigure {
            HistoricalFigure(
                id: id,
                name: name,
                descriptionText: descriptionText,
                gender: gender,
                birthPlace: birthPlace,
                birthDate: date(from: birthDate, using: dateFormatter),
                deathDate: date(from: deathDate, using: dateFormatter),
                occupations: occupations ?? [],
                movements: movements ?? [],
                imageURL: url(from: imageURL),
                imageName: imageName
            )
        }

        private func date(from text: String?, using formatter: DateFormatter) -> Date? {
            guard let text, !text.isEmpty else { return nil }

            guard let date = formatter.date(from: text) else {
                return nil
            }
            return date
        }

        private func url(from text: String?) -> URL? {
            guard let text, !text.isEmpty else { return nil }
            return URL(string: text)
        }
    }
}
