import Foundation

extension WikidataAPI {

    // MARK: - Figure Search

    static func fetchFigures(
        query: String,
        completion: @escaping ([WikidataSearchResult]) -> Void
    ) {
        guard let url = makeSearchURL(
            query: query
        ) else {
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

    // MARK: - Human Filtering

    private static func filterHumanResults(
        _ results: [WikidataSearchResult],
        completion: @escaping ([WikidataSearchResult]) -> Void
    ) {
        let ids = results.map(\.id)

        guard !ids.isEmpty else {
            completion([])
            return
        }

        guard let url = makeEntitiesURL(
            ids: ids,
            properties: "claims"
        ) else {
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

            let humanResults = results.compactMap {
                result -> WikidataSearchResult? in

                guard
                    let entity = response.entities[result.id],
                    entity.isHuman
                else {
                    return nil
                }

                let imageURL = entity.portraitFileName
                    .flatMap(commonsImageURL)

                return WikidataSearchResult(
                    id: result.id,
                    label: result.label,
                    description: result.description,
                    imageURL: imageURL
                )
            }

            completion(humanResults)
        }
    }
}
