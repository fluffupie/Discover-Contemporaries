import SwiftData
import SwiftUI

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
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .tint(.black)
    }
}

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

@MainActor
private let previewContainer: ModelContainer = makePreviewContainer()

#Preview {
    ContentView()
        .modelContainer(previewContainer)
}
