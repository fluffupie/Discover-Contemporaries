import Foundation

/// A historical figure sourced from Wikidata.
///
/// `HistoricalFigure` conforms to four protocols:
/// - `Codable`: Supports encoding and decoding historical figure data.
/// - `Identifiable`: Uses the Wikidata ID to identify figures in SwiftUI lists.
/// - `Hashable`: Supports equality comparisons and use in hash-based collections. Uses ``id`` only.
/// - `Sendable`: Ensures figure data to be safely transferred across cconcurrent tasks and actors.
struct HistoricalFigure: Decodable, Identifiable, Hashable, Sendable {
    /// The Wikidata entity ID, for example `"Q517"`.
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

    // MARK: - Identity
    /// Define equality/hash based solely on id for stable identity in SwiftUI collections.
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    // MARK: - Life Status
    /// The figure's life dates.
    var lifespanInfo: Lifespan {
        Lifespan(birthDate: birthDate, deathDate: deathDate)
    }

    var isProbablyLiving: Bool { lifespanInfo.isProbablyLiving }

    // MARK: - Display Values
    var lifespan: String { lifespanInfo.text }
    var age: Int? { lifespanInfo.age }
    var ageText: String { lifespanInfo.ageText }

    var primaryOccupation: String {
        occupations.first ?? String(localized: "Historical figure")
    }

    var movementsText: String {
        movements.isEmpty
            ? String(localized: "No movement listed")
            : movements.joined(separator: ", ")
    }

    /// A concise secondary line for list rows.
    ///
    /// Prefers ``descriptionText``; otherwise composes occupation, birthplace
    /// and lifespan.
    var subtitle: String? {
        if let description = descriptionText.trimmedNonEmpty {
            return description
        }

        var parts: [String] = []
        if let occupation = occupations.first.trimmedNonEmpty {
            parts.append(occupation)
        }
        if let place = birthPlace.trimmedNonEmpty {
            parts.append(place)
        }
        if birthDate != nil {
            parts.append(lifespan)
        }

        return parts.isEmpty ? nil : parts.joined(separator: " • ")
    }

    // MARK: - Search
    /// Returns whether the figure matches a search query.
    ///
    /// Matching ignores case and diacritics. A blank query matches everything.
    func matches(_ query: String) -> Bool {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }  // Returns true for an empty search query.
        return searchableFields.contains { $0.localizedStandardContains(query) }
    }

    private var searchableFields: [String] {
        var fields = [name]
        fields += [descriptionText, gender, birthPlace].compactMap { $0 }
        fields += occupations
        fields += movements
        fields += [birthDate, deathDate].compactMap {
            $0?.formatted(.dateTime.year())
        }
        return fields
    }
}

/// Provides whitespace-trimming functionality for optional strings.
extension Optional where Wrapped == String {
    /// The string after removing surrounding whitespace and newlines.
    ///
    /// Returns `nil` if the original string is missing
    /// or contains only whitespace.
    var trimmedNonEmpty: String? {
        guard
            let trimmed = self?.trimmingCharacters(in: .whitespacesAndNewlines),
            !trimmed.isEmpty
        else { return nil }
        return trimmed
    }
}
