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

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                completion([])
                return
            }

            do {
                let decoded = try JSONDecoder().decode(
                    WikidataSearchResponse.self,
                    from: data
                )

                filterHumanResults(decoded.search, completion: completion)
            } catch {
                completion([])
            }
        }.resume()
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

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                completion([])
                return
            }

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
            claim.mainsnak.datavalue?.value.id == "Q5"
        } ?? false
    }
}

private struct WikidataClaim: Decodable {
    let mainsnak: WikidataMainSnak
}

private struct WikidataMainSnak: Decodable {
    let datavalue: WikidataDataValue?
}

private struct WikidataDataValue: Decodable {
    let value: WikidataEntityValue
}

private struct WikidataEntityValue: Decodable {
    let id: String?
}
