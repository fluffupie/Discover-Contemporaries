import Foundation

struct AppData: Decodable {
    let figures: [HistoricalFigure]
    let regions: [RegionItem]

    static let empty = AppData(figures: [], regions: [])
}
