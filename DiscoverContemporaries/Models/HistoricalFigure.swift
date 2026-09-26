import Foundation

// The HistoricalFigure model represents one figure

struct HistoricalFigure: Decodable, Identifiable {
    let id: String  // Wikidata ID, e.g. "Q517"
    let name: String
    let description: String?
    //    let era: String
    //    let role: String
    let birthDate: Date?
    let deathDate: Date?
    let region: String?
    let imageURL: URL?

    var lifespan: String {
        guard let birthDate else {
            return "Unknown"
        }

        let birthText = Self.displayDateFormatter.string(from: birthDate)

        guard let deathDate else {
            return "\(birthText) - Present"
        }

        let deathText = Self.displayDateFormatter.string(from: deathDate)

        return "\(birthText) - \(deathText)"
    }

    var ageText: String {
        guard let birthDate else {
            return "Unknown age"
        }

        let endDate = deathDate ?? Date()

        guard
            let age = Calendar.current.dateComponents(
                [.year],
                from: birthDate,
                to: endDate
            ).year
        else {
            return "Unknown age"
        }

        return age == 1 ? "1 year" : "\(age) years"
    }

    func matches(_ query: String) -> Bool {
        [name, lifespan, description ?? "", region ?? ""]
            .joined(separator: " ")
            .localizedCaseInsensitiveContains(query)
    }

    private static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "d MMMM yyyy"
        return formatter
    }()
}
