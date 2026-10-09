import Foundation

extension WikidataAPI {

    // MARK: - Generic Networking

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
            ),
        ]

        return components?.url
    }

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
                value:
                    ids.joined(
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
            ),
        ]

        if let languages {
            queryItems.append(
                URLQueryItem(
                    name: "languages",
                    value: languages
                )
            )
        }

        components?.queryItems =
            queryItems

        return components?.url
    }

    static func request(
        for url: URL
    ) -> URLRequest {
        var request =
            URLRequest(url: url)

        request.setValue(
            "DiscoverContemporaries/1.0 (student project)",
            forHTTPHeaderField:
                "User-Agent"
        )

        request.setValue(
            "application/json",
            forHTTPHeaderField:
                "Accept"
        )

        return request
    }

    // MARK: - Wikimedia Image

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
        let formatter =
            DateFormatter()

        formatter.locale =
            Locale(
                identifier:
                    "en_US_POSIX"
            )

        formatter.calendar =
            Calendar(
                identifier:
                    .gregorian
            )

        formatter.dateFormat =
            "yyyy-MM-dd"

        return formatter
    }()
}
