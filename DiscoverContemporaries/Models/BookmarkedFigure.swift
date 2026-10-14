import Foundation

/// A historical figure saved to the user's bookmarks.
///
/// `BookmarkedFigure` conforms to four protocols:
/// - `Codable`: Supports encoding and decoding bookmark data.
/// - `Identifiable`: Provides a unique identifier for displaying bookmarks in SwiftUI collections.
/// - `Hashable`: Supports equality comparisons and use in hash-based collections. Uses ``id`` only.
/// - `Sendable`: Ensures bookmark data to be safely transferred across concurrency boundaries.
struct BookmarkedFigure: Codable, Identifiable, Hashable, Sendable {
    let id: String  // Identifiable requires an id property.
    let name: String
    let descriptionText: String?
    let gender: String?
    let birthPlace: String?
    let birthDate: Date?
    let deathDate: Date?
    let occupations: [String]
    let movements: [String]
    let imageURL: URL?
    let imageName: String?

    /// When the user saved the figure. Use it to sort the Saves tab.
    let savedAt: Date

    // MARK: - Creation

    /// Creates a bookmark from HistoricalFigure to capture a snapshot at save time ans support sorting via savedAt.
    ///
    /// - Parameters:
    ///   - figure: The figure being saved.
    ///   - savedAt: The save time. Defaults to now.
    init(from figure: HistoricalFigure, savedAt: Date = .now) {
        id = figure.id
        name = figure.name
        descriptionText = figure.descriptionText
        gender = figure.gender
        birthPlace = figure.birthPlace
        birthDate = figure.birthDate
        deathDate = figure.deathDate
        occupations = figure.occupations
        movements = figure.movements
        imageURL = figure.imageURL
        imageName = figure.imageName
        self.savedAt = savedAt
    }
    // MARK: - Decoding

    /// Decodes a bookmark, tolerating data saved by earlier app versions
    /// that lacked the newer fields.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        descriptionText = try c.decodeIfPresent(
            String.self,
            forKey: .descriptionText
        )
        gender = try c.decodeIfPresent(String.self, forKey: .gender)
        birthPlace = try c.decodeIfPresent(String.self, forKey: .birthPlace)
        birthDate = try c.decodeIfPresent(Date.self, forKey: .birthDate)
        deathDate = try c.decodeIfPresent(Date.self, forKey: .deathDate)
        occupations =
            try c.decodeIfPresent([String].self, forKey: .occupations) ?? []
        movements =
            try c.decodeIfPresent([String].self, forKey: .movements) ?? []
        imageURL = try c.decodeIfPresent(URL.self, forKey: .imageURL)
        imageName = try c.decodeIfPresent(String.self, forKey: .imageName)
        savedAt =
            try c.decodeIfPresent(Date.self, forKey: .savedAt) ?? .distantPast
    }
    // MARK: - Identity
    /// Define equality/hash based solely on id for stable identity in SwiftUI collections.
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    // MARK: - Display Values

    /// The figure's life dates.
    var lifespanInfo: Lifespan {
        Lifespan(birthDate: birthDate, deathDate: deathDate)
    }

    /// A formatted birth-to-death range. See ``Lifespan/text``.
    var lifespan: String { lifespanInfo.text }
}

// MARK: - Historical Figure Conversion
/// Conversion back to HistoricalFigure for reuse in UI flows.
extension BookmarkedFigure {
    var historicalFigure: HistoricalFigure {
        HistoricalFigure(
            id: id,
            name: name,
            descriptionText: descriptionText,
            gender: nil,
            birthPlace: nil,
            birthDate: birthDate,
            deathDate: deathDate,
            occupations: [],
            movements: [],
            imageURL: imageURL,
            imageName: imageName
        )
    }
}
