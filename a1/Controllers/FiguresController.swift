import Foundation

final class FiguresController {
    static let shared = FiguresController()

    let appData: AppData

    var figures: [HistoricalFigure] {
        appData.figures
    }

    var regions: [RegionItem] {
        appData.regions
    }

    private init(appData: AppData = FiguresController.loadAppData()) {
        self.appData = appData
    }

    func displayedFigures(for searchText: String, limit: Int = 4) -> [HistoricalFigure] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !query.isEmpty else {
            return Array(figures.prefix(limit))
        }

        return figures.filter { figure in
            figure.matches(query)
        }
    }

    func figure(withID id: String, fallback: HistoricalFigure = .placeholder) -> HistoricalFigure {
        figures.first { $0.id == id } ?? fallback
    }

    func contemporaries(for figure: HistoricalFigure) -> [HistoricalFigure] {
        figure.contemporaries.compactMap { contemporaryID in
            figures.first { $0.id == contemporaryID }
        }
    }

    private static func loadAppData() -> AppData {
        guard let url = Bundle.main.url(forResource: "FiguresData", withExtension: "json") else {
            return .empty
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(AppData.self, from: data)
        } catch {
            return .empty
        }
    }
}
