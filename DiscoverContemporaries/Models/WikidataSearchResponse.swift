import Foundation

struct WikidataSearchResponse: Decodable {
    let search: [WikidataSearchResult]
}

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
