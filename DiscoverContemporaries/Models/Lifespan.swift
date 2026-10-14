import Foundation

/// A birth date and an optional death date, with display helpers.
///
/// A missing ``deathDate`` only means "unknown" in Wikidata, so
/// ``isProbablyLiving`` also checks that the birth date is recent enough for
/// the person to plausibly be alive.
struct Lifespan: Hashable, Sendable {
    /// The date of birth, or `nil` if unknown.
    let birthDate: Date?

    /// The date of death, or `nil` if unknown or the person is living.
    let deathDate: Date?

    /// The oldest age at which a person with no death date is still assumed alive.
    private static let maximumPlausibleAge = 120

    /// Whether the person is plausibly still living.
    var isProbablyLiving: Bool {
        guard deathDate == nil, let birthDate else { return false }
        let years = Calendar.current
            .dateComponents([.year], from: birthDate, to: .now).year ?? 0
        return years <= Self.maximumPlausibleAge
    }

    /// A formatted range such as `"14/03/1879 – 18/04/1955"`.
    ///
    /// The date style follows the user's locale.
    var text: String {
        let unknown = String(localized: "Unknown")
        switch (birthDate, deathDate) {
        case let (birth?, death?):
            return "\(Self.format(birth)) – \(Self.format(death))"
        case let (birth?, nil):
            let end = isProbablyLiving ? String(localized: "Present") : unknown
            return "\(Self.format(birth)) – \(end)"
        case let (nil, death?):
            return "\(unknown) – \(Self.format(death))"
        case (nil, nil):
            return unknown
        }
    }

    /// The age in whole years, or `nil` when it can't be determined reliably.
    var age: Int? {
        guard let birthDate else { return nil }

        let endDate: Date
        if let deathDate {
            endDate = deathDate
        } else if isProbablyLiving {
            endDate = .now
        } else {
            return nil
        }

        guard endDate >= birthDate else { return nil }
        return Calendar.current
            .dateComponents([.year], from: birthDate, to: endDate).year
    }

    /// A display string for ``age``, such as `"Age 76 (at death)"`.
    var ageText: String {
        guard let age else { return String(localized: "Unknown age") }
        return deathDate == nil
            ? String(localized: "Age \(age)")
            : String(localized: "Age \(age) (at death)")
    }

    private static func format(_ date: Date) -> String {
        date.formatted(date: .numeric, time: .omitted)
    }
}
