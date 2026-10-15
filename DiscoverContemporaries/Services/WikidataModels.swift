import Foundation

/// Additional Wikidata details for a historical figure.
nonisolated struct WikidataFigureDetails: Sendable {
    let birthDate: Date?
    let deathDate: Date?
    let portraitURL: URL?
    let birthPlaceID: String?
    let citizenshipID: String?
}

/// The decoded entity response returned by Wikidata.
nonisolated struct WikidataEntitiesResponse: Decodable, Sendable {
    let entities: [String: WikidataEntity]
}

/// A Wikidata entity with its claims, labels and descriptions.
nonisolated struct WikidataEntity: Decodable, Sendable {
    let claims: [String: [WikidataClaim]]?
    let labels: [String: WikidataLabel]?
    let descriptions: [String: WikidataLabel]?

    var englishLabel: String? { labels?["en"]?.value }
    var englishDescription: String? { descriptions?["en"]?.value }

    /// Whether the entity is an instance (P31) of human (Q5).
    var isHuman: Bool { entityIDs(for: "P31").contains("Q5") }

    /// Birthplace entity IDs (P19).
    var birthPlaceIDs: [String] { entityIDs(for: "P19") }

    /// Citizenship entity IDs (P27).
    var citizenshipIDs: [String] { entityIDs(for: "P27") }

    /// The Commons file name of the portrait (P18), if any.
    var portraitFileName: String? {
        claims?["P18"]?.lazy.compactMap { $0.mainsnak.datavalue?.stringValue }.first
    }

    /// Date of birth (P569), if present and parseable.
    var birthDate: Date? { date(for: "P569") }

    /// Date of death (P570), if present and parseable.
    var deathDate: Date? { date(for: "P570") }

    // MARK: - Helpers

    private func entityIDs(for property: String) -> [String] {
        claims?[property]?.compactMap { $0.mainsnak.datavalue?.value?.id } ?? []
    }

    private func date(for property: String) -> Date? {
        claims?[property]?
            .lazy
            .compactMap { $0.mainsnak.datavalue?.value?.time }
            .first
            .flatMap(WikidataAPI.parseWikidataTime)
    }
}

/// A localized Wikidata label value.
nonisolated struct WikidataLabel: Decodable, Sendable {
    let value: String
}

/// A single Wikidata claim.
nonisolated struct WikidataClaim: Decodable, Sendable {
    let mainsnak: WikidataMainSnak
}

/// The main statement value of a claim.
nonisolated struct WikidataMainSnak: Decodable, Sendable {
    let datavalue: WikidataDataValue?
}

/// A data value that is either a structured object or a plain string.
///
/// Wikidata's `value` is an object for entities and times (`id`, `time`) but a
/// bare string for file names such as portraits. Each decode is attempted
/// separately, and the one that doesn't match simply becomes `nil`.
nonisolated struct WikidataDataValue: Decodable, Sendable {
    let value: WikidataEntityValue?
    let stringValue: String?

    private enum CodingKeys: String, CodingKey {
        case value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        value = try? container.decode(WikidataEntityValue.self, forKey: .value)
        stringValue = try? container.decode(String.self, forKey: .value)
    }
}

/// Structured data inside a claim value.
nonisolated struct WikidataEntityValue: Decodable, Sendable {
    let id: String?
    let time: String?
}
