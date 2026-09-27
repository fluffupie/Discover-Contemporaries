import Foundation

struct WikidataAPI {

    static func fetchFigures(
        query: String,
        completion: @escaping ([WikidataSearchResult]) -> Void
    ) {
        var components = URLComponents(
            string: "https://www.wikidata.org/w/api.php"
        )!

        components.queryItems = [
            URLQueryItem(name: "action", value: "wbsearchentities"),
            URLQueryItem(name: "search", value: query),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "type", value: "item"),
            URLQueryItem(name: "limit", value: "20")
        ]

        guard let url = components.url else {
            completion([])
            return
        }

        URLSession.shared.dataTask(with: request(for: url)) { data, _, error in
            guard let data = data, error == nil else {
                completion([])
                return
            }

            Task { @MainActor in
                do {
                    let decoded = try JSONDecoder().decode(
                        WikidataSearchResponse.self,
                        from: data
                    )

                    filterHumanResults(decoded.search, completion: completion)
                } catch {
                    completion([])
                }
            }
        }.resume()
    }

    static func fetchPortraitURL(
        forID id: String,
        completion: @escaping (URL?) -> Void
    ) {
        var components = URLComponents(
            string: "https://www.wikidata.org/w/api.php"
        )!

        components.queryItems = [
            URLQueryItem(name: "action", value: "wbgetentities"),
            URLQueryItem(name: "ids", value: id),
            URLQueryItem(name: "props", value: "claims"),
            URLQueryItem(name: "format", value: "json")
        ]

        guard let url = components.url else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: request(for: url)) { data, _, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }

            Task { @MainActor in
                do {
                    let decoded = try JSONDecoder().decode(
                        WikidataEntitiesResponse.self,
                        from: data
                    )
                    let fileName = decoded.entities[id]?.portraitFileName
                    completion(fileName.flatMap(commonsImageURL))
                } catch {
                    completion(nil)
                }
            }
        }.resume()
    }

    private static func commonsImageURL(for fileName: String) -> URL? {
        guard let encodedFileName = fileName.addingPercentEncoding(
            withAllowedCharacters: .urlPathAllowed
        ) else {
            return nil
        }

        return URL(
            string: "https://commons.wikimedia.org/wiki/Special:FilePath/\(encodedFileName)?width=500"
        )
    }

    private static func request(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue(
            "DiscoverContemporaries/1.0 (student project; s4084278@student.rmit.edu.au)",
            forHTTPHeaderField: "User-Agent"
        )
        return request
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

        var components = URLComponents(
            string: "https://www.wikidata.org/w/api.php"
        )!

        components.queryItems = [
            URLQueryItem(name: "action", value: "wbgetentities"),
            URLQueryItem(name: "ids", value: ids.joined(separator: "|")),
            URLQueryItem(name: "props", value: "claims"),
            URLQueryItem(name: "format", value: "json")
        ]

        guard let url = components.url else {
            completion([])
            return
        }

        URLSession.shared.dataTask(with: request(for: url)) { data, _, error in
            guard let data = data, error == nil else {
                completion([])
                return
            }

            Task { @MainActor in
                do {
                    let decoded = try JSONDecoder().decode(
                        WikidataEntitiesResponse.self,
                        from: data
                    )
                    let humanIDs = Set(
                        decoded.entities
                            .filter { $0.value.isHuman }
                            .map(\.key)
                    )
                    let humanResults = results.filter { humanIDs.contains($0.id) }
                    completion(humanResults)
                } catch {
                    completion([])
                }
            }
        }.resume()
    }
}

private struct WikidataEntitiesResponse: Decodable {
    let entities: [String: WikidataEntity]
}

private struct WikidataEntity: Decodable {
    let claims: [String: [WikidataClaim]]?

    var isHuman: Bool {
        claims?["P31"]?.contains { claim in
            claim.mainsnak.datavalue?.value?.id == "Q5"
        } ?? false
    }

    var portraitFileName: String? {
        claims?["P18"]?.compactMap { claim in
            claim.mainsnak.datavalue?.stringValue
        }.first
    }
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
        let container = try decoder.container(keyedBy: CodingKeys.self)
        value = try? container.decode(WikidataEntityValue.self, forKey: .value)
        stringValue = try? container.decode(String.self, forKey: .value)
    }
}

private struct WikidataEntityValue: Decodable {
    let id: String?
}
