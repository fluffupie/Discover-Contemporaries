import Foundation
import OSLog

private nonisolated let networkLogger = Logger(subsystem: "a2.DiscoverContemporaries", category: "Wikidata")

extension WikidataAPI {
    // MARK: - Generic Networking

    /// Fetches and decodes a Wikidata response.
    ///
    /// - Parameters:
    ///   - url: The request URL.
    ///   - type: The response type to decode.
    ///   - session: The session to use. Defaults to `URLSession.shared`.
    /// - Throws: ``WikidataError/badStatus(_:)`` for a non-2xx response,
    ///   ``WikidataError/decodingFailed`` if decoding fails, or the underlying
    ///   `URLError` (including cancellation).
    nonisolated static func fetch<T: Decodable & Sendable>(
        url: URL,
        as type: T.Type,
        session: URLSession = .shared
    ) async throws -> T {
        let (data, response) = try await session.data(for: request(for: url))

        if let http = response as? HTTPURLResponse,
           !(200...299).contains(http.statusCode) {
            networkLogger.error("HTTP \(http.statusCode) for \(url.absoluteString, privacy: .public)")
            throw WikidataError.badStatus(http.statusCode)
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            networkLogger.error("Decoding \(String(describing: T.self), privacy: .public) failed: \(error)")
            throw WikidataError.decodingFailed
        }
    }

    /// Callback version of ``fetch(url:as:session:)``.
    ///
    /// The completion runs on the main actor and receives `nil` on any failure.
    @available(*, deprecated, message: "Use the async fetch(url:as:) instead.")
    static func fetch<T: Decodable & Sendable>(
        url: URL,
        as type: T.Type,
        completion: @escaping @MainActor (T?) -> Void
    ) {
        Task { @MainActor in
            completion(try? await fetch(url: url, as: type))
        }
    }

    // MARK: - URL Construction

    /// Creates a Wikidata entity-search URL.
    ///
    /// - Parameters:
    ///   - query: The search text. Surrounding whitespace is trimmed.
    ///   - limit: The maximum number of results. Defaults to 20.
    /// - Returns: The URL, or `nil` if `query` is blank or the URL can't be built.
    static func makeSearchURL(query: String, limit: Int = 20) -> URL? {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty, var components = URLComponents(string: baseURL) else {
            return nil
        }

        components.queryItems = [
            URLQueryItem(name: "action", value: "wbsearchentities"),
            URLQueryItem(name: "search", value: query),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "type", value: "item"),
            URLQueryItem(name: "limit", value: String(limit))
        ]

        return components.url
    }

    /// Creates a Wikidata entity-details URL.
    ///
    /// - Parameters:
    ///   - ids: The entity IDs to request.
    ///   - properties: The `props` value, for example `"claims|labels"`.
    ///   - languages: An optional language filter for labels and descriptions.
    /// - Returns: The URL, or `nil` if `ids` is empty or the URL can't be built.
    static func makeEntitiesURL(
        ids: [String],
        properties: String,
        languages: String? = nil
    ) -> URL? {
        guard !ids.isEmpty, var components = URLComponents(string: baseURL) else {
            return nil
        }

        var queryItems = [
            URLQueryItem(name: "action", value: "wbgetentities"),
            URLQueryItem(name: "ids", value: ids.joined(separator: "|")),
            URLQueryItem(name: "props", value: properties),
            URLQueryItem(name: "format", value: "json")
        ]

        if let languages {
            queryItems.append(URLQueryItem(name: "languages", value: languages))
        }

        components.queryItems = queryItems
        return components.url
    }

    /// Creates a request with the headers Wikimedia requires.
    ///
    /// - Parameter url: The destination URL.
    nonisolated static func request(for url: URL) -> URLRequest {
        var request = URLRequest(url: url, timeoutInterval: 20)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }

    /// Wikimedia asks for an app name plus a way to contact you.
    nonisolated static let userAgent = "DiscoverContemporaries/1.0"

    // MARK: - Wikimedia Image

    /// Creates a Wikimedia Commons URL for a file, 500 pixels wide.
    ///
    /// - Parameter fileName: The Commons file name.
    /// - Returns: The URL, or `nil` if the name can't be encoded.
    nonisolated static func commonsImageURL(for fileName: String) -> URL? {
        guard let encoded = fileName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            return nil
        }

        return URL(string: "https://commons.wikimedia.org/wiki/Special:FilePath/\(encoded)?width=500")
    }

    // MARK: - Date Parsing

    /// Converts a Wikidata time string into a `Date`.
    ///
    /// The date is the start of that day in the device's time zone, which
    /// matches how the seed data is parsed. Wikidata marks unknown month or
    /// day parts as `00`, and those are read as `01`, so `+1564-00-00T00:00:00Z`
    /// becomes 1 January 1564.
    ///
    /// - Parameter time: A value such as `+1452-04-15T00:00:00Z`.
    /// - Returns: The date, or `nil` for BCE dates and malformed values.
    nonisolated static func parseWikidataTime(_ time: String) -> Date? {
        guard !time.hasPrefix("-") else { return nil }  // BCE

        let datePart = time.drop(while: { $0 == "+" }).prefix { $0 != "T" }
        let parts = datePart.split(separator: "-", omittingEmptySubsequences: false)

        guard parts.count == 3,
              let year = Int(parts[0]), year >= 1,
              let month = Int(parts[1]),
              let day = Int(parts[2])
        else { return nil }

        let components = DateComponents(year: year, month: max(month, 1), day: max(day, 1))
        guard (1...12).contains(components.month!), (1...31).contains(components.day!) else {
            return nil
        }

        return Calendar(identifier: .gregorian).date(from: components)
    }
}
