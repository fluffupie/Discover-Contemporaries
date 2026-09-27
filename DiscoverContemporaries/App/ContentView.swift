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
private let previewContainer: ModelContainer = {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: CachedHistoricalFigure.self,
        configurations: configuration
    )

    let figures = [
        CachedHistoricalFigure(
            wikidataID: "Q762",
            name: "Leonardo da Vinci",
            descriptionText: "Artist, inventor, scientist, polymath, and one of the defining minds of the Renaissance.",
            gender: "Male",
            country: "Italy",
            placeOfBirth: "Vinci, Republic of Florence",
            imageName: "da-vinci",
            occupations: ["Polymath", "Artist"],
            movements: ["Renaissance"]
        ),
        CachedHistoricalFigure(
            wikidataID: "ada-lovelace",
            name: "Ada Lovelace",
            descriptionText: "Known for early work on Charles Babbage's Analytical Engine and ideas about computing.",
            gender: "Female",
            country: "England",
            placeOfBirth: "London, England",
            imageName: "ada-lovelace",
            occupations: ["Mathematician", "Writer"]
        ),
        CachedHistoricalFigure(
            wikidataID: "vincent-van-gogh",
            name: "Vincent van Gogh",
            descriptionText: "Dutch Post-Impressionist painter.",
            gender: "Male",
            country: "Netherlands",
            placeOfBirth: "Zundert, Netherlands",
            imageName: "vincent-van-gogh",
            occupations: ["Artist", "Painter"],
            movements: ["Post-Impressionism"]
        ),
        CachedHistoricalFigure(
            wikidataID: "queen-elizabeth",
            name: "Elizabeth II",
            descriptionText: "Former Queen of the United Kingdom.",
            gender: "Female",
            country: "United Kingdom",
            placeOfBirth: "London, England",
            imageName: "elizabeth-II",
            occupations: ["Monarch"]
        )
    ]

    for figure in figures {
        container.mainContext.insert(figure)
    }

    return container
}()

#Preview {
    ContentView()
        .modelContainer(previewContainer)
}
