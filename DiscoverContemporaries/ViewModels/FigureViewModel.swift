import Foundation
import Combine

// view model is the brain of one screen

@MainActor
final class FigureViewModel: ObservableObject {
    
    @Published var searchText: String = ""
    @Published var searchResults: [WikidataSearchResult] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    func searchFigures() {
        let query = searchText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        WikidataAPI.fetchFigures(query: query) {
            [weak self] results in
            DispatchQueue.main.async{
                guard let self else {return}
                
                self.searchResults = results
                self.isLoading = false
                
                if results.isEmpty {
                    self.errorMessage = "No figures found."
                }
            }
        }
    }
}
