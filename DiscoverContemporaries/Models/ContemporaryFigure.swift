import Foundation

/// A lightweight summary of a figure who lived at the same time as another
/// ``HistoricalFigure``.
///
/// It carries only what a list row needs: identity, name, life dates and a
/// portrait URL. Fetch the full ``HistoricalFigure`` by ``id`` when the user
/// opens a detail screen.
struct ContemporaryFigure: Identifiable, Hashable, Sendable {
    let id: String // Identifiable requires an id property.
    let name: String
    let birthDate: Date?
    let deathDate: Date?
    let imageURL: URL?

    // MARK: - Equality
    /// Define equality/hash based solely on id for stable identity in SwiftUI collections.
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    // MARK: - Display Values

    /// The figure's life dates.
    var lifespan: Lifespan {
        Lifespan(birthDate: birthDate, deathDate: deathDate)
    }

    /// A formatted birth-to-death range.
    var lifespanText: String { lifespan.text }

    /// A display string for the figure's age.
    var ageText: String { lifespan.ageText }

    // MARK: - Conversion
    /// Conversion back to HistoricalFigure for reuse in UI flows.
    var historicalFigure: HistoricalFigure {
        HistoricalFigure(
            id: id,
            name: name,
            descriptionText: nil,
            gender: nil,
            birthPlace: nil,
            birthDate: birthDate,
            deathDate: deathDate,
            occupations: [],
            movements: [],
            imageURL: imageURL,
            imageName: nil
        )
    }
}
