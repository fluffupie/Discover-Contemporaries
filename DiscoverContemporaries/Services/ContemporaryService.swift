import Foundation

@MainActor
enum ContemporaryService {
    /// Returns well-known historical figures whose lifespans overlap with the target figure.
        ///
        /// The service first uses figures already stored in SwiftData, fetches any
        /// missing curated figures from Wikidata, and then filters and ranks the
        /// candidates locally.
        ///
        /// - Parameters:
        ///   - target: The historical figure whose contemporaries should be found.
        ///   - repository: The repository used to read and cache historical figures.
        ///   - completion: A closure containing up to 20 matching contemporaries.

    static func fetchContemporaries(
        for target: HistoricalFigure,
        repository: FigureCacheRepository,
        completion: @escaping ([ContemporaryFigure]) -> Void
    ) {
        guard target.birthDate != nil else {
            completion([])
            return
        }

        let candidateIDs = candidateIDs(
            excluding: target.id
        )

        // 1. Use anything already stored locally.
        let cachedFigures =
            (try? repository.fetchFigures(
                withIDs: candidateIDs
            )) ?? []

        let cachedIDs = Set(
            cachedFigures.map(\.id)
        )

        // 2. Work out which curated figures are missing.
        let missingIDs = candidateIDs.filter {
            !cachedIDs.contains($0)
        }

        // Everything is already local.
        guard !missingIDs.isEmpty else {
            completion(
                makeContemporaries(
                    for: target,
                    from: cachedFigures
                )
            )

            return
        }

        // 3. Fetch only missing figures.
        WikidataAPI.fetchFiguresInBatches(
            withIDs: missingIDs
        ) { fetchedFigures in

            do {
                try repository.saveAll(
                    fetchedFigures
                )
            } catch {
                print(
                    "Failed to cache contemporary candidates: \(error)"
                )
            }

            // 4. Reload the complete candidate pool.
            let allFigures =
                (try? repository.fetchFigures(
                    withIDs: candidateIDs
                )) ?? []

            completion(
                makeContemporaries(
                    for: target,
                    from: allFigures
                )
            )
        }
    }

    // MARK: - Candidate Pool

    private static func candidateIDs(
        excluding targetID: String
    ) -> [String] {
        let combined =
        ContinentFigureIDs.allIDs +
            OccupationFigureSeeds.allIDs

        var seen = Set<String>()

        return combined.filter { id in
            guard id != targetID else {
                return false
            }

            return seen.insert(id).inserted
        }
    }

    // MARK: - Filtering

    private static func makeContemporaries(
        for target: HistoricalFigure,
        from candidates: [HistoricalFigure]
    ) -> [ContemporaryFigure] {
        guard let targetBirth = target.birthDate else {
            return []
        }

        let targetEnd =
            target.deathDate ?? Date()

        let matchingFigures = candidates
            .filter { candidate in
                guard
                    candidate.id != target.id,
                    let candidateBirth = candidate.birthDate
                else {
                    return false
                }

                let candidateEnd =
                    candidate.deathDate ?? Date()

                return candidateBirth <= targetEnd &&
                    candidateEnd >= targetBirth
            }
            .sorted { first, second in
                birthDistance(
                    from: targetBirth,
                    to: first.birthDate
                )
                <
                birthDistance(
                    from: targetBirth,
                    to: second.birthDate
                )
            }

        return matchingFigures
            .prefix(20)
            .map { figure in
                ContemporaryFigure(
                    id: figure.id,
                    name: figure.name,
                    birthDate: figure.birthDate,
                    deathDate: figure.deathDate,
                    imageURL: figure.imageURL
                )
            }
    }

    private static func birthDistance(
        from targetBirth: Date,
        to candidateBirth: Date?
    ) -> TimeInterval {
        guard let candidateBirth else {
            return .greatestFiniteMagnitude
        }

        return abs(
            candidateBirth.timeIntervalSince(
                targetBirth
            )
        )
    }
}
