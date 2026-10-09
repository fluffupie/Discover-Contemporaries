import Foundation

extension WikidataAPI {

    // MARK: - Generic Networking

    /// Fetches and decodes a Wikidata response into the requested decodable type.
    ///
    /// The completion handler is called on the main actor.
    ///
    /// - Parameters:
    ///   - url: The URL of the Wikidata request.
    ///   - type: The response type to decode.
    ///   - completion: A closure containing the decoded response, or `nil` if the request fails.
    static func fetch<T: Decodable>(
        url: URL,
        as type: T.Type,
        completion: @escaping (T?) -> Void
    ) {
        URLSession.shared
            .dataTask(
                with: request(for: url)
            ) { data, response, error in

                if let error {
                    print(
                        "Wikidata request failed: \(error)"
                    )

                    Task { @MainActor in
                        completion(nil)
                    }

                    return
                }

                if let httpResponse =
                    response as? HTTPURLResponse
                {
                    guard
                        (200...299)
                            .contains(
                                httpResponse.statusCode
                            )
                    else {
                        print(
                            "Wikidata HTTP error: \(httpResponse.statusCode)"
                        )

                        Task { @MainActor in
                            completion(nil)
                        }

                        return
                    }
                }

                guard let data else {
                    Task { @MainActor in
                        completion(nil)
                    }

                    return
                }

                do {
                    let decoded =
                        try JSONDecoder().decode(
                            T.self,
                            from: data
                        )

                    Task { @MainActor in
                        completion(decoded)
                    }

                } catch {
                    print(
                        "Wikidata decoding failed: \(error)"
                    )

                    Task { @MainActor in
                        completion(nil)
                    }
                }
            }
            .resume()
    }

    // MARK: - URL Construction

    /// Creates a Wikidata entity-search URL for the supplied query.
    ///
    /// - Parameter query: The search text used to find Wikidata entities.
    /// - Returns: A configured search URL, or `nil` if the URL cannot be created.
    static func makeSearchURL(
        query: String
    ) -> URL? {
        var components =
            URLComponents(
                string: baseURL
            )

        components?.queryItems = [
            URLQueryItem(
                name: "action",
                value: "wbsearchentities"
            ),
            URLQueryItem(
                name: "search",
                value: query
            ),
            URLQueryItem(
                name: "language",
                value: "en"
            ),
            URLQueryItem(
                name: "format",
                value: "json"
            ),
            URLQueryItem(
                name: "type",
                value: "item"
            ),
            URLQueryItem(
                name: "limit",
                value: "20"
            )
        ]

        return components?.url
    }

    /// Creates a Wikidata entity-details URL for the supplied entity IDs and properties.
    ///
    /// - Parameters:
    ///   - ids: The Wikidata entity IDs to request.
    ///   - properties: The Wikidata properties to include in the response.
    ///   - languages: An optional language filter for returned labels.
    /// - Returns: A configured entity URL, or `nil` if the URL cannot be created.
    static func makeEntitiesURL(
        ids: [String],
        properties: String,
        languages: String? = nil
    ) -> URL? {
        var components =
            URLComponents(
                string: baseURL
            )

        var queryItems = [
            URLQueryItem(
                name: "action",
                value: "wbgetentities"
            ),
            URLQueryItem(
                name: "ids",
                value: ids.joined(
                    separator: "|"
                )
            ),
            URLQueryItem(
                name: "props",
                value: properties
            ),
            URLQueryItem(
                name: "format",
                value: "json"
            )
        ]

        if let languages {
            queryItems.append(
                URLQueryItem(
                    name: "languages",
                    value: languages
                )
            )
        }

        components?.queryItems = queryItems

        return components?.url
    }

    /// Creates a URL request with the headers required for Wikidata requests.
    ///
    /// - Parameter url: The destination URL for the request.
    /// - Returns: A configured URL request.
    static func request(
        for url: URL
    ) -> URLRequest {
        var request =
            URLRequest(url: url)

        request.setValue(
            "DiscoverContemporaries/1.0 (student project)",
            forHTTPHeaderField: "User-Agent"
        )

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Accept"
        )

        return request
    }

    // MARK: - Wikimedia Image

    /// Creates a Wikimedia Commons image URL for the specified file name.
    ///
    /// - Parameter fileName: The Wikimedia Commons file name.
    /// - Returns: A URL for a 500-pixel-wide image, or `nil` if the file name cannot be encoded.
    nonisolated static func commonsImageURL(
        for fileName: String
    ) -> URL? {
        guard
            let encodedFileName =
                fileName.addingPercentEncoding(
                    withAllowedCharacters:
                        .urlPathAllowed
                )
        else {
            return nil
        }

        return URL(
            string:
                "https://commons.wikimedia.org/wiki/Special:FilePath/\(encodedFileName)?width=500"
        )
    }

    // MARK: - Date Parsing

    /// Converts a Wikidata time string into a `Date`.
    ///
    /// - Parameter time: A Wikidata time value such as `+1452-04-15T00:00:00Z`.
    /// - Returns: The parsed date, or `nil` if the value cannot be converted.
    static func parseWikidataTime(
        _ time: String
    ) -> Date? {
        let trimmed =
            time.hasPrefix("+")
            ? String(
                time.dropFirst()
            )
            : time

        guard
            let datePart =
                trimmed
                    .split(
                        separator: "T"
                    )
                    .first
        else {
            return nil
        }

        return wikidataDateFormatter.date(
            from: String(datePart)
        )
    }

    private static let wikidataDateFormatter: DateFormatter = {
        let formatter = DateFormatter()

        formatter.locale =
            Locale(
                identifier: "en_US_POSIX"
            )

        formatter.calendar =
            Calendar(
                identifier: .gregorian
            )

        formatter.dateFormat =
            "yyyy-MM-dd"

        return formatter
    }()
}
