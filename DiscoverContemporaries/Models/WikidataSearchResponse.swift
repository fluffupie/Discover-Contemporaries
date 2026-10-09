import Foundation

/// Represents the decoded response returned by a Wikidata search request.
struct WikidataSearchResponse: Decodable {
    let search: [WikidataSearchResult]
}

/// Represents a single historical figure returned from Wikidata search results.
struct WikidataSearchResult: Decodable, Identifiable {
    let id: String
    let label: String
    let description: String?
    let imageURL: URL?

    init(
        id: String,
        label: String,
        description: String?,
        imageURL: URL? = nil
    ) {
        self.id = id
        self.label = label
        self.description = description
        self.imageURL = imageURL
    }
}
