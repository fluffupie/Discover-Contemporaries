import Foundation

struct WikidataAPI {

    private static let baseURL = "https://www.wikidata.org/w/api.php"

    // MARK: - Public API

    static func fetchFigures(
        query: String,
        completion: @escaping ([WikidataSearchResult]) -> Void
    ) {
        guard let url = makeSearchURL(query: query) else {
            completion([])
            return
        }

        fetch(
            url: url,
            as: WikidataSearchResponse.self
        ) { response in
            guard let response else {
                completion([])
                return
            }

            filterHumanResults(
                response.search,
                completion: completion
            )
        }
    }

    static func fetchDetails(
        forID id: String,
        completion: @escaping (WikidataFigureDetails?) -> Void
    ) {
        guard
            let url = makeEntitiesURL(
                ids: [id],
                properties: "claims"
            )
        else {
            completion(nil)
            return
        }

        fetch(
            url: url,
            as: WikidataEntitiesResponse.self
        ) { response in
            guard
                let entity = response?.entities[id]
            else {
                completion(nil)
                return
            }

            let details = WikidataFigureDetails(
                birthDate: entity.birthDate,
                deathDate: entity.deathDate,
                portraitURL: entity.portraitFileName
                    .flatMap(commonsImageURL),
                countryID: entity.countryIDs.first
            )

            completion(details)
        }
    }

    static func fetchCountryName(
        forID id: String,
        completion: @escaping (String?) -> Void
    ) {
        fetchDetails(forID: id) { details in
            guard let countryID = details?.countryID else {
                completion(nil)
                return
            }

            fetchEntityLabel(
                forID: countryID,
                completion: completion
            )
        }
    }

    // MARK: - Supporting Requests

    static func fetchEntityLabel(
        forID id: String,
        completion: @escaping (String?) -> Void
    ) {
        guard
            let url = makeEntitiesURL(
                ids: [id],
                properties: "labels",
                languages: "en"
            )
        else {
            completion(nil)
            return
        }

        fetch(
            url: url,
            as: WikidataEntitiesResponse.self
        ) { response in
            completion(
                response?
                    .entities[id]?
                    .englishLabel
            )
        }
    }

    private static func filterHumanResults(
        _ results: [WikidataSearchResult],
        completion: @escaping ([WikidataSearchResult]) -> Void
    ) {
        let ids = results.map(\.id)

        guard !ids.isEmpty else {
            completion([])
            return
        }

        guard
            let url = makeEntitiesURL(
                ids: ids,
                properties: "claims"
            )
        else {
            completion([])
            return
        }

        fetch(
            url: url,
            as: WikidataEntitiesResponse.self
        ) { response in
            guard let response else {
                completion([])
                return
            }

            let humanIDs = Set(
                response.entities
                    .filter { $0.value.isHuman }
                    .map(\.key)
            )

            let humanResults = results.filter {
                humanIDs.contains($0.id)
            }

            completion(humanResults)
        }
    }

    // MARK: - Networking

    private static func fetch<T: Decodable>(
        url: URL,
        as type: T.Type,
        completion: @escaping (T?) -> Void
    ) {
        URLSession.shared
            .dataTask(with: request(for: url)) { data, _, error in
                guard
                    let data,
                    error == nil
                else {
                    Task { @MainActor in
                        completion(nil)
                    }

                    return
                }

                do {
                    let decoded = try JSONDecoder().decode(
                        T.self,
                        from: data
                    )

                    Task { @MainActor in
                        completion(decoded)
                    }
                } catch {
                    Task { @MainActor in
                        completion(nil)
                    }
                }
            }
            .resume()
    }

    private static func makeSearchURL(
        query: String
    ) -> URL? {
        var components = URLComponents(
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

    private static func makeEntitiesURL(
        ids: [String],
        properties: String,
        languages: String? = nil
    ) -> URL? {
        var components = URLComponents(
            string: baseURL
        )

        var queryItems = [
            URLQueryItem(
                name: "action",
                value: "wbgetentities"
            ),
            URLQueryItem(
                name: "ids",
                value: ids.joined(separator: "|")
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

        components?.queryItems = queryItems

        return components?.url
    }

    private static func request(
        for url: URL
    ) -> URLRequest {
        var request = URLRequest(url: url)

        request.setValue(
            "DiscoverContemporaries/1.0 (student project)",
            forHTTPHeaderField: "User-Agent"
        )

        return request
    }

    // MARK: - Formatting

    private static func commonsImageURL(
        for fileName: String
    ) -> URL? {
        guard
            let encodedFileName = fileName.addingPercentEncoding(
                withAllowedCharacters: .urlPathAllowed
            )
        else {
            return nil
        }

        return URL(
            string:
                "https://commons.wikimedia.org/wiki/Special:FilePath/\(encodedFileName)?width=500"
        )
    }

    fileprivate static func parseWikidataTime(
        _ time: String
    ) -> Date? {
        let trimmed =
            time.hasPrefix("+")
            ? String(time.dropFirst())
            : time

        guard
            let datePart =
                trimmed
                .split(separator: "T")
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

// MARK: - Figure Details

struct WikidataFigureDetails {
    let birthDate: Date?
    let deathDate: Date?
    let portraitURL: URL?
    let countryID: String?
}

// MARK: - Wikidata Response Models

private struct WikidataEntitiesResponse: Decodable {
    let entities: [String: WikidataEntity]
}

private struct WikidataEntity: Decodable {
    let claims: [String: [WikidataClaim]]?
    let labels: [String: WikidataLabel]?

    var isHuman: Bool {
        claims?["P31"]?.contains { claim in
            claim.mainsnak
                .datavalue?
                .value?
                .id == "Q5"
        } ?? false
    }

    var countryIDs: [String] {
        claims?["P27"]?.compactMap { claim in
            claim.mainsnak
                .datavalue?
                .value?
                .id
        } ?? []
    }

    var englishLabel: String? {
        labels?["en"]?.value
    }

    var portraitFileName: String? {
        claims?["P18"]?
            .compactMap { claim in
                claim.mainsnak
                    .datavalue?
                    .stringValue
            }
            .first
    }

    var birthDate: Date? {
        guard
            let time = claims?["P569"]?
                .compactMap({
                    $0.mainsnak
                        .datavalue?
                        .value?
                        .time
                })
                .first
        else {
            return nil
        }

        return WikidataAPI.parseWikidataTime(time)
    }

    var deathDate: Date? {
        guard
            let time = claims?["P570"]?
                .compactMap({
                    $0.mainsnak
                        .datavalue?
                        .value?
                        .time
                })
                .first
        else {
            return nil
        }

        return WikidataAPI.parseWikidataTime(time)
    }
}

private struct WikidataLabel: Decodable {
    let value: String
}

private struct WikidataClaim: Decodable {
    let mainsnak: WikidataMainSnak
}

private struct WikidataMainSnak: Decodable {
    let datavalue: WikidataDataValue?
}

private struct WikidataDataValue: Decodable {
    let value: WikidataEntityValue?
    let stringValue: String?

    private enum CodingKeys: String, CodingKey {
        case value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )

        value = try? container.decode(
            WikidataEntityValue.self,
            forKey: .value
        )

        stringValue = try? container.decode(
            String.self,
            forKey: .value
        )
    }
}

private struct WikidataEntityValue: Decodable {
    let id: String?
    let time: String?
}
