import SwiftUI

struct HistoricalFigure: Decodable, Identifiable {
    let id: String
    let name: String
    let era: String
    let role: String
    let birthDate: String
    let deathDate: String?
    let accent: String
    let imageName: String
    let flag: String
    let summary: String
    let contemporaries: [String]

    var accentColor: Color {
        switch accent {
        case "coral":
            return .coral
        case "fern":
            return .fern
        case "midnight":
            return .midnight
        case "ochre":
            return .ochre
        case "emerald":
            return .emerald
        default:
            return .smoke
        }
    }

    var lifespan: String {
        guard let birth = Self.isoDateFormatter.date(from: birthDate) else {
            return "Unknown"
        }

        let birthText = Self.displayDateFormatter.string(from: birth)
        guard let deathDate else {
            return "\(birthText) - Present"
        }

        guard let death = Self.isoDateFormatter.date(from: deathDate) else {
            return birthText
        }

        return "\(birthText) - \(Self.displayDateFormatter.string(from: death))"
    }

    var ageText: String {
        guard let age = completedAge else {
            return "Unknown age"
        }

        return age == 1 ? "1 year" : "\(age) years"
    }

    private var completedAge: Int? {
        guard let startDate = Self.isoDateFormatter.date(from: birthDate) else {
            return nil
        }

        let endDate: Date
        if let deathDate {
            guard let parsedDeathDate = Self.isoDateFormatter.date(from: deathDate) else {
                return nil
            }
            endDate = parsedDeathDate
        } else {
            endDate = Date()
        }

        return Calendar.current.dateComponents([.year], from: startDate, to: endDate).year
    }

    func matches(_ query: String) -> Bool {
        [name, era, role, lifespan, birthDate, deathDate ?? "", flag, summary]
            .joined(separator: " ")
            .localizedCaseInsensitiveContains(query)
    }

    private static let isoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "d MMMM yyyy"
        return formatter
    }()

    static let placeholder = HistoricalFigure(
        id: "placeholder",
        name: "Historical Figure",
        era: "Profile",
        role: "Featured profile",
        birthDate: "1900-01-01",
        deathDate: nil,
        accent: "smoke",
        imageName: "margaret-thatcher",
        flag: "🇬🇧",
        summary: "A profile from the historical figures collection.",
        contemporaries: []
    )
}
