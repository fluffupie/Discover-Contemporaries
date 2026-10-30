import Foundation

extension WikidataAPI {
    // MARK: - Figure Search

    /// Searches Wikidata for historical figures matching a query.
    ///
    /// Only human entities are returned, in Wikidata's relevance order. Each
    /// search makes two requests: one for the matches and one for their claims,
    /// which are used to filter out non-humans and find portraits.
    ///
    /// - Parameter query: The search text. A blank query returns `[]`.
    /// - Returns: The matching people, possibly empty.
    /// - Throws: ``WikidataError`` or the underlying `URLError` if a request
    ///   fails, including cancellation.
    static func fetchFigures(query: String) async throws -> [WikidataSearchResult] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        guard let url = makeSearchURL(query: query) else {
            throw WikidataError.invalidURL
        }

        let response = try await fetch(url: url, as: WikidataSearchResponse.self)
        return try await filterHumanResults(response.search)
    }

    /// Callback version of ``fetchFigures(query:)``.
    ///
    /// The completion runs on the main actor and receives `[]` on any failure.
    @available(*, deprecated, message: "Use the async fetchFigures(query:) instead.")
    static func fetchFigures(
        query: String,
        completion: @escaping @MainActor ([WikidataSearchResult]) -> Void
    ) {
        Task { @MainActor in
            completion((try? await fetchFigures(query: query)) ?? [])
        }
    }

    // MARK: - Human Filtering

    /// Keeps only the results that are humans and attaches their portraits.
    private static func filterHumanResults(
        _ results: [WikidataSearchResult]
    ) async throws -> [WikidataSearchResult] {
        guard !results.isEmpty else { return [] }

        guard let url = makeEntitiesURL(
            ids: results.map(\.id),
            properties: "claims"
        ) else {
            throw WikidataError.invalidURL
        }

        let response = try await fetch(url: url, as: WikidataEntitiesResponse.self)

        return results.compactMap { result in
            guard let entity = response.entities[result.id], entity.isHuman else {
                return nil
            }

            var human = result
            human.imageURL = entity.portraitFileName.flatMap(commonsImageURL)
            return human
        }
    }
    
    struct SparqlResponse: Decodable {
        struct Head: Decodable { let vars: [String] }
        struct Results: Decodable {
            struct BindingValue: Decodable { let type: String; let value: String }
            struct Binding: Decodable {
                let personLabel: BindingValue?
                let countryLabel: BindingValue?
            }
            let bindings: [Binding]
        }
        let head: Head
        let results: Results
    }

    static func fetchBirthCountry(forID id: String, session: URLSession = .shared) async throws -> String? {
        let sparql = """
        SELECT ?person ?personLabel ?countryLabel WHERE {
          VALUES ?person { wd:\(id) }
          ?person wdt:P19 ?birthPlace.
          OPTIONAL { ?birthPlace wdt:P17 ?countryDirect. }
          OPTIONAL {
            ?birthPlace (wdt:P131)* ?admin.
            ?admin wdt:P17 ?countryViaAdmin.
          }
          BIND(COALESCE(?countryDirect, ?countryViaAdmin) AS ?country)
          SERVICE wikibase:label { bd:serviceParam wikibase:language "[AUTO_LANGUAGE],en". }
        }
        LIMIT 1
        """

        guard var components = URLComponents(string: "https://query.wikidata.org/sparql") else {
            throw WikidataError.invalidURL
        }
        components.queryItems = [
            URLQueryItem(name: "query", value: sparql),
            URLQueryItem(name: "format", value: "json")
        ]
        guard let url = components.url else { throw WikidataError.invalidURL }

        var request = URLRequest(url: url, timeoutInterval: 20)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/sparql-results+json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw WikidataError.badStatus(http.statusCode)
        }

        let decoded = try JSONDecoder().decode(SparqlResponse.self, from: data)
        return decoded.results.bindings.first?.countryLabel?.value
    }
}
