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
}
