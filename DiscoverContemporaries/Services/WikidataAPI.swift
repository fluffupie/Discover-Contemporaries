import Foundation

struct WikidataAPI {

    static func fetchFigures(
        query: String,
        completion: @escaping ([WikidataSearchResult]) -> Void
    ) {

        // builds a Wikidata request URL
        var components = URLComponents(
            string: "https://www.wikidata.org/w/api.php"
        )!

        components.queryItems = [
            URLQueryItem(name: "action", value: "wbsearchentities"),
            URLQueryItem(name: "search", value: query),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "type", value: "item"),
            URLQueryItem(name: "limit", value: "10"),
        ]

        guard let url = components.url else {
            completion([])
            return
        }

        // sends the request with URLSession
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                completion([])
                return
            }

            do {
                // decodes it into WikidataSearchResponse
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
