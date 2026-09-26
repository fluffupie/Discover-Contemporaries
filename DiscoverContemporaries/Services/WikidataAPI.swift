import Foundation

struct WikidataAPI {
    
    // REST API call and date processing
    static func fetchFigures(query: String, completion: @escaping ([WikidataSearchResult]) -> Void) {
        
        var components = URLComponents(string: "https://www.wikidata.org/w/api/php")!
        
        components.queryItems = [
            URLQueryItem(name: "action", value: "wbsearchentities"),
            URLQueryItem(name: "search", value: query),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "type", value: "item"),
            URLQueryItem(name: "limit", value: "10")
        ]
        
        guard let url = components.url else {
            completion([])
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                completion([])
                return
            }
            
            do {
                let decoded = try JSONDecoder().decode(
                    WikidataSearchResponse.self,
                    from: data
                )
                
                completion(decoded.search)
            } catch {
                completion([])
            }
            
        }.resume()
    }
}
