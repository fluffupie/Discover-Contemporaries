import Foundation

struct HistoricalFigure: Decodable, Identifiable {
    let id: String  // Wikidata ID, e.g. "Q517"
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
    
    // MARK: - Display Values
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

    var age: Int? {
            guard let birthDate else {
                return nil
            }

            let endDate = deathDate ?? Date()

            guard endDate >= birthDate else {
                return nil
            }

            return Calendar.current
                .dateComponents(
                    [.year],
                    from: birthDate,
                    to: endDate
                )
                .year
        }

        var ageText: String {
            guard let age else {
                return "Unknown age"
            }

            return deathDate == nil
                ? "Age \(age)"
                : "Age \(age) (at death)"
        }
    
    var primaryOccupation: String {
            occupations.first ?? "Historical figure"
        }

        var movementsText: String {
            movements.isEmpty
                ? "No movement listed"
                : movements.joined(separator: ", ")
        }
    
    // MARK: - Search

        func matches(_ query: String) -> Bool {
            searchText.localizedCaseInsensitiveContains(query)
        }

        private var searchText: String {
            [
                name,
                lifespan,
                descriptionText ?? "",
                gender ?? "",
                birthPlace ?? "",
                occupations.joined(separator: " "),
                movements.joined(separator: " ")
            ]
            .joined(separator: " ")
        }

    // MARK: - Formatting

        static let displayDateFormatter: DateFormatter = {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.dateFormat = "d MMM yyyy"
            return formatter
        }()
}

