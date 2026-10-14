import Foundation

/// Represents a continent used for geographical exploration.
///
/// Conforms to `Identifiable` to support displaying continents
/// in SwiftUI collections such as `List` and `ForEach`.
struct Continent: Identifiable {
    let id: String // Identifiable requires an id property.
    let name: String
    let systemImage: String
}
