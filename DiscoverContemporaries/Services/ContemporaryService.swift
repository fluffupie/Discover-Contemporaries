import Foundation
import OSLog

private let contemporaryLogger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "DiscoverContemporaries",
    category: "Contemporaries"
)

/// Finds well-known figures who lived at the same time as a given figure.
@MainActor
enum ContemporaryService {
    /// The default maximum number of contemporaries returned.
    static let defaultLimit = 20

    /// Returns figures whose lifespans overlap with the target's.
    ///
    /// Candidates come from the curated continent and occupation lists. Figures
    /// already in SwiftData are used first, missing ones are fetched from
    /// Wikidata and cached, and the pool is then filtered and ranked locally.
    /// Results are ordered by how close their birth date is to the target's.
    ///
    /// If the network request fails but some candidates are cached, the cached
    /// ones are used and the failure is logged.
    ///
    /// - Parameters:
    ///   - target: The figure whose contemporaries to find.
    ///   - repository: The repository used to read and cache figures.
    ///   - limit: The maximum number of results. Defaults to ``defaultLimit``.
    /// - Returns: The contemporaries, or `[]` if the target's life dates can't
    ///   be determined.
    /// - Throws: The network error if nothing was cached and the fetch failed,
    ///   or `CancellationError`.
    static func fetchContemporaries(
        for target: HistoricalFigure,
        repository: FigureCacheRepository,
        limit: Int = defaultLimit
    ) async throws -> [ContemporaryFigure] {
        let now = Date.now
        guard let targetRange = activeRange(of: target, now: now) else {
            return []
        }

        let candidateIDs = candidateIDs(excluding: target.id)

        // 1. Use anything already stored locally.
        let cached = (try? repository.fetchFigures(withIDs: candidateIDs)) ?? []
        var pool = cached

        // 2. Fetch only the curated figures we don't have yet.
        let cachedIDs = Set(cached.map(\.id))
        let missingIDs = candidateIDs.filter { !cachedIDs.contains($0) }

        if !missingIDs.isEmpty {
            do {
                let fetched = try await WikidataAPI.fetchFiguresInBatches(withIDs: missingIDs)
                pool += fetched

                do {
                    try repository.saveAll(fetched)
                } catch {
                    contemporaryLogger.error(
                        "Failed to cache candidates: \(error.localizedDescription)"
                    )
                }
            } catch {
                try Task.checkCancellation()
                if cached.isEmpty { throw error }
                contemporaryLogger.error(
                    "Fetch failed, using cached candidates only: \(error.localizedDescription)"
                )
            }
        }

        // 3. Filter and rank.
        return makeContemporaries(
            for: target,
            targetRange: targetRange,
            from: pool,
            limit: limit,
            now: now
        )
    }

    // MARK: - Candidate Pool

    /// Every curated figure ID, without duplicates.
    private static let allCandidateIDs: [String] = {
        var seen = Set<String>()
        return (ContinentFigureIDs.allIDs + OccupationFigureSeeds.allIDs)
            .filter { seen.insert($0).inserted }
    }()

    private static func candidateIDs(excluding targetID: String) -> [String] {
        allCandidateIDs.filter { $0 != targetID }
    }

    // MARK: - Filtering

    /// The span from birth to death, or to now for a figure who is probably
    /// still living. `nil` if the dates are missing, inconsistent, or the end
    /// is unknown.
    private static func activeRange(
        of figure: HistoricalFigure,
        now: Date
    ) -> ClosedRange<Date>? {
        guard let birth = figure.birthDate else { return nil }

        let end: Date
        if let death = figure.deathDate {
            end = death
        } else if figure.isProbablyLiving {
            end = now
        } else {
            return nil
        }

        return end >= birth ? birth...end : nil
    }

    private static func makeContemporaries(
        for target: HistoricalFigure,
        targetRange: ClosedRange<Date>,
        from candidates: [HistoricalFigure],
        limit: Int,
        now: Date
    ) -> [ContemporaryFigure] {
        candidates
            .filter { $0.id != target.id }
            .compactMap { candidate -> (figure: HistoricalFigure, distance: TimeInterval)? in
                guard
                    let range = activeRange(of: candidate, now: now),
                    range.overlaps(targetRange)
                else {
                    return nil
                }

                let distance = abs(
                    range.lowerBound.timeIntervalSince(targetRange.lowerBound)
                )
                return (candidate, distance)
            }
            .sorted { ($0.distance, $0.figure.name) < ($1.distance, $1.figure.name) }
            .prefix(limit)
            .map { entry in
                ContemporaryFigure(
                    id: entry.figure.id,
                    name: entry.figure.name,
                    birthDate: entry.figure.birthDate,
                    deathDate: entry.figure.deathDate,
                    imageURL: entry.figure.imageURL
                )
            }
    }
}
