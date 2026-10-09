import Foundation

/// Provides access to historical figure data from Wikidata.
struct WikidataAPI {

    static let baseURL =
        "https://www.wikidata.org/w/api.php"

    static let sparqlURL =
        "https://query.wikidata.org/sparql"

    private static func wikidataID(
        from uri: String
    ) -> String? {
        URL(string: uri)?
            .lastPathComponent
    }

    private static let iso8601Formatter =
        ISO8601DateFormatter()

    private static func parseSPARQLDate(
        _ value: String
    ) -> Date? {
        iso8601Formatter.date(from: value)
    }

    private static let sparqlDateFormatter: DateFormatter = {
        let formatter = DateFormatter()

        formatter.locale = Locale(
            identifier: "en_US_POSIX"
        )

        formatter.calendar = Calendar(
            identifier: .gregorian
        )

        formatter.dateFormat = "yyyy-MM-dd"

        return formatter
    }()
}
