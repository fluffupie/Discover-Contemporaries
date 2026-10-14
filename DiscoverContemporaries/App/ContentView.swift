import SwiftData
import SwiftUI

/// ## Tabs
///
/// | Tab | Destination | Purpose |
/// | --- | --- | --- |
/// | Home | ``HomeView`` | The main landing feed. |
/// | Explore | ``ExploreView`` | Discover new figures. |
/// | Saves | ``BookmarkView`` | Figures the user has saved. |
struct ContentView: View {
    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }

            NavigationStack {
                ExploreView()
            }
            .tabItem {
                Label("Explore", systemImage: "safari.fill")
            }
            
            NavigationStack {
                BookmarkView()
            }
            .tabItem {
                Label("Saves", systemImage: "heart")
            }
        }
        .tint(.primary)
    }
}

// MARK: - Preview Support
/// Creates an in-memory SwiftData model container for use in previews.
@MainActor
private func makePreviewContainer() -> ModelContainer {
    let schema = Schema([])
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    do {
        return try ModelContainer(for: schema, configurations: configuration)
    } catch {
        fatalError("Failed to create preview ModelContainer: \(error)")
    }
}

/// Shared in-memory container injected into `ContentView` previews.
@MainActor
private let previewContainer: ModelContainer = makePreviewContainer()

#Preview {
    ContentView()
        .modelContainer(previewContainer)
}
