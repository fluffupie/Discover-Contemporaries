import Foundation

extension WikidataAPI {

    // MARK: - Figure Batch Fetch
    /// Fetches historical figures matching the supplied Wikidata entity IDs.
        ///
        /// The returned figures preserve the order of the supplied IDs.
        ///
        /// - Parameters:
        ///   - ids: The Wikidata entity IDs to fetch.
        ///   - completion: A closure containing the fetched historical figures.
    static func fetchFigures(
        withIDs ids: [String],
        completion: @escaping ([HistoricalFigure]) -> Void
    ) {
        guard !ids.isEmpty else {
            completion([])
            return
        }

        guard let url = makeEntitiesURL(
            ids: ids,
            properties: "claims|labels|descriptions"
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

            var figuresByID: [String: HistoricalFigure] = [:]

            for (id, entity) in response.entities {
                guard let name = entity.englishLabel else {
                    continue
                }

                figuresByID[id] = HistoricalFigure(
                    id: id,
                    name: name,
                    descriptionText: entity.englishDescription,
                    gender: nil,
                    birthPlace: nil,
                    birthDate: entity.birthDate,
                    deathDate: entity.deathDate,
                    occupations: [],
                    movements: [],
                    imageURL: entity.portraitFileName
                        .flatMap(commonsImageURL),
                    imageName: nil
                )
            }

            completion(
                ids.compactMap {
                    figuresByID[$0]
                }
            )
        }
    }
    
    /// Fetches a large collection of historical figures in smaller batches.
        ///
        /// - Parameters:
        ///   - ids: The Wikidata entity IDs to fetch.
        ///   - batchSize: The maximum number of IDs requested in each batch.
        ///   - completion: A closure containing all figures collected from the batches.
    static func fetchFiguresInBatches(
        withIDs ids: [String],
        batchSize: Int = 50,
        completion: @escaping ([HistoricalFigure]) -> Void
    ) {
        guard !ids.isEmpty else {
            completion([])
            return
        }

        let batches = stride(
            from: 0,
            to: ids.count,
            by: batchSize
        ).map { startIndex in

            let endIndex = min(
                startIndex + batchSize,
                ids.count
            )

            return Array(
                ids[startIndex..<endIndex]
            )
        }

        fetchNextBatch(
            batches,
            index: 0,
            collected: [],
            completion: completion
        )
    }

    private static func fetchNextBatch(
        _ batches: [[String]],
        index: Int,
        collected: [HistoricalFigure],
        completion: @escaping ([HistoricalFigure]) -> Void
    ) {
        guard index < batches.count else {
            completion(collected)
            return
        }

        fetchFigures(
            withIDs: batches[index]
        ) { figures in

            fetchNextBatch(
                batches,
                index: index + 1,
                collected: collected + figures,
                completion: completion
            )
        }
    }

    // MARK: - Figure Details
    /// Fetches additional Wikidata details for the specified historical figure.
       ///
       /// - Parameters:
       ///   - id: The Wikidata entity ID of the figure.
       ///   - completion: A closure containing the figure details, or `nil` if they cannot be retrieved.
    static func fetchDetails(
        forID id: String,
        completion: @escaping (WikidataFigureDetails?) -> Void
    ) {
        guard let url = makeEntitiesURL(
            ids: [id],
            properties: "claims"
        ) else {
            completion(nil)
            return
        }

        fetch(
            url: url,
            as: WikidataEntitiesResponse.self
        ) { response in

            guard let entity = response?.entities[id] else {
                completion(nil)
                return
            }

            completion(
                WikidataFigureDetails(
                    birthDate: entity.birthDate,
                    deathDate: entity.deathDate,
                    portraitURL: entity.portraitFileName
                        .flatMap(commonsImageURL),
                    birthPlaceID: entity.birthPlaceIDs.first,
                    citizenshipID: entity.citizenshipIDs.first
                )
            )
        }
    }

    // MARK: - Birth Place
    /// Fetches the English name of a historical figure's birthplace.
       ///
       /// - Parameters:
       ///   - id: The Wikidata entity ID of the historical figure.
       ///   - completion: A closure containing the birthplace name, or `nil` if unavailable.
    static func fetchBirthPlaceName(
        forFigureID id: String,
        completion: @escaping (String?) -> Void
    ) {
        fetchDetails(
            forID: id
        ) { details in

            guard let birthPlaceID = details?.birthPlaceID else {
                completion(nil)
                return
            }

            fetchEntityLabel(
                forID: birthPlaceID,
                completion: completion
            )
        }
    }

    // MARK: - Citizenship
    /// Fetches the English name of a historical figure's citizenship.
       ///
       /// - Parameters:
       ///   - id: The Wikidata entity ID of the historical figure.
       ///   - completion: A closure containing the citizenship name, or `nil` if unavailable.
    static func fetchCitizenshipName(
        forFigureID id: String,
        completion: @escaping (String?) -> Void
    ) {
        fetchDetails(
            forID: id
        ) { details in

            guard let citizenshipID = details?.citizenshipID else {
                completion(nil)
                return
            }

            fetchEntityLabel(
                forID: citizenshipID,
                completion: completion
            )
        }
    }

    // MARK: - Entity Label
    /// Fetches the English label for the specified Wikidata entity.
        ///
        /// - Parameters:
        ///   - id: The Wikidata entity ID whose label should be retrieved.
        ///   - completion: A closure containing the English label, or `nil` if unavailable.
    static func fetchEntityLabel(
        forID id: String,
        completion: @escaping (String?) -> Void
    ) {
        guard let url = makeEntitiesURL(
            ids: [id],
            properties: "labels",
            languages: "en"
        ) else {
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
}
