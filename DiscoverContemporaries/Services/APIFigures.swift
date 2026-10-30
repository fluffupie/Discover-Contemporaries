import Foundation
import OSLog

private let wikidataLogger = Logger(
    subsystem: "com.ninabasically.DiscoverContemporaries",
    category: "Wikidata"
)

extension WikidataAPI {
    /// The most entity IDs Wikidata accepts in one `wbgetentities` request.
    static let maxIDsPerRequest = 50

    // MARK: - Figure Batch Fetch

    /// Fetches the figures for the given Wikidata IDs in one request.
    ///
    /// Results keep the order of `ids`. Duplicate IDs are removed, and entities
    /// with no English label are skipped.
    ///
    /// - Parameter ids: At most ``maxIDsPerRequest`` IDs. Use
    ///   ``fetchFiguresInBatches(withIDs:batchSize:)`` for more.
    /// - Throws: ``WikidataError`` if the request fails.
    static func fetchFigures(withIDs ids: [String]) async throws
        -> [HistoricalFigure]
    {
        let ids = uniqued(ids)
        guard !ids.isEmpty else { return [] }

        guard
            let url = makeEntitiesURL(
                ids: ids,
                properties: "claims|labels|descriptions",
                languages: "en"
            )
        else {
            throw WikidataError.invalidURL
        }

        let response = try await fetch(
            url: url,
            as: WikidataEntitiesResponse.self
        )

        var figuresByID: [String: HistoricalFigure] = [:]
        for (id, entity) in response.entities {
            guard let name = entity.englishLabel else {
                wikidataLogger.notice(
                    "Skipping \(id, privacy: .public): no English label"
                )
                continue
            }

            figuresByID[id] = HistoricalFigure(
                id: id,
                name: name,
                descriptionText: entity.englishDescription,
                gender: nil,
                birthPlace: nil,
                birthDate: entity.birthDate,
                deathDate: entity.deathDate,
                occupations: [],
                movements: [],
                imageURL: entity.portraitFileName.flatMap(commonsImageURL),
                imageName: nil
            )
        }

        return ids.compactMap { figuresByID[$0] }
    }

    /// Fetches any number of figures by splitting `ids` into sequential requests.
    ///
    /// Results keep the order of `ids`. A failed batch is logged and skipped so
    /// the other batches still return.
    ///
    /// - Parameters:
    ///   - ids: The Wikidata entity IDs to fetch.
    ///   - batchSize: IDs per request, clamped to 1...``maxIDsPerRequest``.
    /// - Throws: The last error if every batch failed, or `CancellationError`.
    static func fetchFiguresInBatches(
        withIDs ids: [String],
        batchSize: Int = maxIDsPerRequest
    ) async throws -> [HistoricalFigure] {
        let ids = uniqued(ids)
        guard !ids.isEmpty else { return [] }

        let size = min(max(batchSize, 1), maxIDsPerRequest)
        var figures: [HistoricalFigure] = []
        var lastError: Error?
        var succeeded = 0

        for start in stride(from: 0, to: ids.count, by: size) {
            try Task.checkCancellation()
            let batch = Array(ids[start..<min(start + size, ids.count)])

            do {
                figures += try await fetchFigures(withIDs: batch)
                succeeded += 1
            } catch {
                wikidataLogger.error(
                    "Batch at \(start) failed: \(error.localizedDescription)"
                )
                lastError = error
            }
        }

        if succeeded == 0, let lastError { throw lastError }
        return figures
    }

    // MARK: - Figure Details

    /// Fetches birth and death dates, portrait and place IDs for a figure.
    ///
    /// - Returns: The details, or `nil` if Wikidata has no such entity.
    /// - Throws: ``WikidataError`` if the request fails.
    static func fetchDetails(forID id: String) async throws
        -> WikidataFigureDetails?
    {
        guard let url = makeEntitiesURL(ids: [id], properties: "claims") else {
            throw WikidataError.invalidURL
        }

        let response = try await fetch(
            url: url,
            as: WikidataEntitiesResponse.self
        )
        guard let entity = response.entities[id] else { return nil }

        return WikidataFigureDetails(
            birthDate: entity.birthDate,
            deathDate: entity.deathDate,
            portraitURL: entity.portraitFileName.flatMap(commonsImageURL),
            birthPlaceID: entity.birthPlaceIDs.first,
            citizenshipID: entity.citizenshipIDs.first
        )
    }

    // MARK: - Birth Place and Citizenship

    /// Fetches the English names of a figure's birthplace and citizenship
    /// with one claims request and one label request.
    static func fetchBirthPlaceAndCitizenship(
        forFigureID id: String
    ) async throws -> (birthPlace: String?, citizenship: String?) {
        guard let details = try await fetchDetails(forID: id) else {
            return (nil, nil)
        }

        let wanted = [details.birthPlaceID, details.citizenshipID].compactMap {
            $0
        }
        guard !wanted.isEmpty else { return (nil, nil) }

        let labels = try await fetchEntityLabels(forIDs: wanted)
        return (
            details.birthPlaceID.flatMap { labels[$0] },
            details.citizenshipID.flatMap { labels[$0] }
        )
    }

    /// The English name of a figure's birthplace, or `nil` if unavailable.
    static func fetchBirthPlaceName(forFigureID id: String) async throws
        -> String?
    {
        try await fetchBirthPlaceAndCitizenship(forFigureID: id).birthPlace
    }

    /// The English name of a figure's citizenship, or `nil` if unavailable.
    static func fetchCitizenshipName(forFigureID id: String) async throws
        -> String?
    {
        try await fetchBirthPlaceAndCitizenship(forFigureID: id).citizenship
    }

    // MARK: - Entity Labels

    /// Fetches English labels for several entities in one request.
    ///
    /// - Returns: A dictionary of ID to label. Entities without an English
    ///   label are absent.
    static func fetchEntityLabels(forIDs ids: [String]) async throws -> [String:
        String]
    {
        let ids = uniqued(ids)
        guard !ids.isEmpty else { return [:] }

        guard
            let url = makeEntitiesURL(
                ids: ids,
                properties: "labels",
                languages: "en"
            )
        else {
            throw WikidataError.invalidURL
        }

        let response = try await fetch(
            url: url,
            as: WikidataEntitiesResponse.self
        )
        return response.entities.compactMapValues(\.englishLabel)
    }

    /// The English label for one entity, or `nil` if it has none.
    static func fetchEntityLabel(forID id: String) async throws -> String? {
        try await fetchEntityLabels(forIDs: [id])[id]
    }

    // MARK: - Helpers

    /// Removes duplicates, keeping the first occurrence of each ID.
    private static func uniqued(_ ids: [String]) -> [String] {
        var seen = Set<String>()
        return ids.filter { seen.insert($0).inserted }
    }
}
