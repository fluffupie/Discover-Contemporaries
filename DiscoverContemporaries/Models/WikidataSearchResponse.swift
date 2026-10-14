import Foundation

/// The decoded response from a Wikidata `wbsearchentities` request.
///
/// Contains an array of historical figure search results returned by the Wikidata API.
///
/// Conforms to:
/// - `Decodable`: Supports decoding the JSON response.
/// - `Sendable`: Ensures response data to be safely transferred across cconcurrent tasks and actors.
nonisolated struct WikidataSearchResponse: Decodable, Sendable {
    /// The entities returned by the Wikidata search request.
    let search: [WikidataSearchResult]
}

/// A single entity returned from a Wikidata search request.
/// Conforms to:
/// - `Decodable`: Supports decoding entity data from JSON.
/// - `Identifiable`: Uses the Wikidata ID to identify the search result.
/// - `Hashable`: Supports equality comparisons and hash-based collections.
/// - `Sendable`: Ensures search results to be safely transferred across cconcurrent tasks and actors.
struct WikidataSearchResult: Decodable, Identifiable, Hashable, Sendable {
    let id: String
    let label: String
    let description: String?
    var imageURL: URL?

    /// Maps the JSON response keys to the corresponding properties.
    /// Wikidata search results don't necessarily include portrait URLs.
    /// By excluding imageURL from decoding, the application can populate it separately after retrieving additional information.
    private enum CodingKeys: String, CodingKey {
        case id, label, description
    }
}

// MARK: - Custom Decoding

extension WikidataSearchResult {
    /// Decodes a result, using the entity ID as the label when none is given.
    ///
    /// The initializer is implemented in an extension to preserve
    /// the structure's automatically generated memberwise initializer.
    ///
    /// - Parameter decoder: The decoder containing the entity data.
    /// - Throws: A decoding error if the required entity ID
    ///   is missing or contains an invalid value.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        self.id = id
        self.label =
            try container.decodeIfPresent(String.self, forKey: .label) ?? id
        self.description = try container.decodeIfPresent(
            String.self,
            forKey: .description
        )
    }
}
