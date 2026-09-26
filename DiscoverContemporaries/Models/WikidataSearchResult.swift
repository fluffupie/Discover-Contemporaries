import Foundation

struct WikidataSearchResponse: Decodable {
    let search: [WikidataSearchResult]
}

struct WikidataSearchResult: Decodable, Identifiable {
    let id: String
    let label: String
    let description: String?
}
