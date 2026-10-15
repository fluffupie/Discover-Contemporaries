import Foundation

/// Errors thrown by the Wikidata helpers.
enum WikidataError: LocalizedError {
    /// A request URL couldn't be built.
    case invalidURL
    /// The server answered with a non-2xx status code.
    case badStatus(Int)
    /// The response body couldn't be decoded.
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            String(localized: "Couldn't build the Wikidata request.")
        case .badStatus(let code):
            String(localized: "Wikidata returned an error (\(code)).")
        case .decodingFailed:
            String(localized: "Couldn't read the response from Wikidata.")
        }
    }
}
