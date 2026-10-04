import Foundation

struct WikidataAPI {
    // REST API call and data processing
    static func fetchFigures(
        query: String,
        completion: @escaping ([WikidataSearchResult]) -> Void
    ) {
        var components = URLComponents(
            string: "https://www.wikidata.org/w/api.php"
        )!

        components.queryItems = [
            URLQueryItem(name: "action", value: "wbsearchentities"),
            URLQueryItem(name: "search", value: query),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "type", value: "item"),
            URLQueryItem(name: "limit", value: "20")
        ]

        guard let url = components.url else {
            completion([])
            return
        }

        URLSession.shared.dataTask(with: request(for: url)) { data, _, error in
            guard let data = data, error == nil else {
                completion([])
                return
            }

            Task { @MainActor in
                do {
                    let decoded = try JSONDecoder().decode(
                        WikidataSearchResponse.self,
                        from: data
                    )

                    filterHumanResults(decoded.search, completion: completion)
                } catch {
                    completion([])
                }
            }
        }.resume()
    }

    static func fetchCountryName(
        for figure: HistoricalFigure,
        completion: @escaping (String?) -> Void
    ) {
        if figure.id.hasPrefix("Q") {
            fetchCountryName(forID: figure.id, completion: completion)
        } else {
            fetchFigures(query: figure.name) { results in
                guard let id = results.first?.id else {
                    completion(nil)
                    return
                }

                fetchCountryName(forID: id, completion: completion)
            }
        }
    }
    
    static func fetchLifespan(
        forID id: String,
        completion: @escaping (Date?, Date?) -> Void
    ) {
        var components = URLComponents(
            string: "https://www.wikidata.org/w/api.php"
        )!

        components.queryItems = [
            URLQueryItem(name: "action", value: "wbgetentities"),
            URLQueryItem(name: "ids", value: id),
            URLQueryItem(name: "props", value: "claims"),
            URLQueryItem(name: "format", value: "json")
        ]

        guard let url = components.url else {
            completion(nil, nil)
            return
        }

        URLSession.shared.dataTask(with: request(for: url)) { data, _, error in
            guard let data = data, error == nil else {
                completion(nil, nil)
                return
            }

            Task { @MainActor in
                do {
                    let decoded = try JSONDecoder().decode(
                        WikidataEntitiesResponse.self,
                        from: data
                    )
                    let entity = decoded.entities[id]
                    let birth = entity?.birthDate
                    let death = entity?.deathDate
                    completion(birth, death)
                } catch {
                    completion(nil, nil)
                }
            }
        }.resume()
    }

    static func fetchPortraitURL(
        forID id: String,
        completion: @escaping (URL?) -> Void
    ) {
        var components = URLComponents(
            string: "https://www.wikidata.org/w/api.php"
        )!

        components.queryItems = [
            URLQueryItem(name: "action", value: "wbgetentities"),
            URLQueryItem(name: "ids", value: id),
            URLQueryItem(name: "props", value: "claims"),
            URLQueryItem(name: "format", value: "json")
        ]

        guard let url = components.url else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: request(for: url)) { data, _, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }

            Task { @MainActor in
                do {
                    let decoded = try JSONDecoder().decode(
                        WikidataEntitiesResponse.self,
                        from: data
                    )
                    let fileName = decoded.entities[id]?.portraitFileName
                    completion(fileName.flatMap(commonsImageURL))
                } catch {
                    completion(nil)
                }
            }
        }.resume()
    }

    private static func fetchCountryName(
        forID id: String,
        completion: @escaping (String?) -> Void
    ) {
        var components = URLComponents(
            string: "https://www.wikidata.org/w/api.php"
        )!

        components.queryItems = [
            URLQueryItem(name: "action", value: "wbgetentities"),
            URLQueryItem(name: "ids", value: id),
            URLQueryItem(name: "props", value: "claims"),
            URLQueryItem(name: "format", value: "json")
        ]

        guard let url = components.url else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: request(for: url)) { data, _, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }

            Task { @MainActor in
                do {
                    let decoded = try JSONDecoder().decode(
                        WikidataEntitiesResponse.self,
                        from: data
                    )
                    guard let countryID = decoded.entities[id]?.countryIDs.first else {
                        completion(nil)
                        return
                    }

                    fetchEntityLabel(forID: countryID, completion: completion)
                } catch {
                    completion(nil)
                }
            }
        }.resume()
    }

    private static func fetchEntityLabel(
        forID id: String,
        completion: @escaping (String?) -> Void
    ) {
        var components = URLComponents(
            string: "https://www.wikidata.org/w/api.php"
        )!

        components.queryItems = [
            URLQueryItem(name: "action", value: "wbgetentities"),
            URLQueryItem(name: "ids", value: id),
            URLQueryItem(name: "props", value: "labels"),
            URLQueryItem(name: "languages", value: "en"),
            URLQueryItem(name: "format", value: "json")
        ]

        guard let url = components.url else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: request(for: url)) { data, _, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }

            Task { @MainActor in
                do {
                    let decoded = try JSONDecoder().decode(
                        WikidataEntitiesResponse.self,
                        from: data
                    )
                    completion(decoded.entities[id]?.englishLabel)
                } catch {
                    completion(nil)
                }
            }
        }.resume()
    }

    private static func commonsImageURL(for fileName: String) -> URL? {
        guard let encodedFileName = fileName.addingPercentEncoding(
            withAllowedCharacters: .urlPathAllowed
        ) else {
            return nil
        }

        return URL(
            string: "https://commons.wikimedia.org/wiki/Special:FilePath/\(encodedFileName)?width=500"
        )
    }

    private static func request(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue(
            "DiscoverContemporaries/1.0 (student project; s4084278@student.rmit.edu.au)",
            forHTTPHeaderField: "User-Agent"
        )
        return request
    }
    
    fileprivate static func parseWikidataTime(_ time: String) -> Date? {
        // Wikidata time format example: "+1879-03-14T00:00:00Z"
        let trimmed = time.hasPrefix("+") ? String(time.dropFirst()) : time
        guard let datePart = trimmed.split(separator: "T").first else { return nil }
        let dateString = String(datePart)
        return wikidataDateFormatter.date(from: dateString)
    }
    
    private static let wikidataDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static func filterHumanResults(
        _ results: [WikidataSearchResult],
        completion: @escaping ([WikidataSearchResult]) -> Void
    ) {
        let ids = results.map(\.id)

        guard !ids.isEmpty else {
            completion([])
            return
        }

        var components = URLComponents(
            string: "https://www.wikidata.org/w/api.php"
        )!

        components.queryItems = [
            URLQueryItem(name: "action", value: "wbgetentities"),
            URLQueryItem(name: "ids", value: ids.joined(separator: "|")),
            URLQueryItem(name: "props", value: "claims"),
            URLQueryItem(name: "format", value: "json")
        ]

        guard let url = components.url else {
            completion([])
            return
        }

        URLSession.shared.dataTask(with: request(for: url)) { data, _, error in
            guard let data = data, error == nil else {
                completion([])
                return
            }

            Task { @MainActor in
                do {
                    let decoded = try JSONDecoder().decode(
                        WikidataEntitiesResponse.self,
                        from: data
                    )
                    let humanIDs = Set(
                        decoded.entities
                            .filter { $0.value.isHuman }
                            .map(\.key)
                    )
                    let humanResults = results.filter { humanIDs.contains($0.id) }
                    completion(humanResults)
                } catch {
                    completion([])
                }
            }
        }.resume()
    }
}

private struct WikidataEntitiesResponse: Decodable {
    let entities: [String: WikidataEntity]
}

private struct WikidataEntity: Decodable {
    let claims: [String: [WikidataClaim]]?
    let labels: [String: WikidataLabel]?

    var isHuman: Bool {
        claims?["P31"]?.contains { claim in
            claim.mainsnak.datavalue?.value?.id == "Q5"
        } ?? false
    }

    var countryIDs: [String] {
        claims?["P27"]?.compactMap { claim in
            claim.mainsnak.datavalue?.value?.id
        } ?? []
    }

    var englishLabel: String? {
        labels?["en"]?.value
    }

    var portraitFileName: String? {
        claims?["P18"]?.compactMap { claim in
            claim.mainsnak.datavalue?.stringValue
        }.first
    }
    
    var birthDate: Date? {
        guard let time = claims?["P569"]?.compactMap({ $0.mainsnak.datavalue?.value?.time }).first else {
            return nil
        }
        return WikidataAPI.parseWikidataTime(time)
    }

    var deathDate: Date? {
        guard let time = claims?["P570"]?.compactMap({ $0.mainsnak.datavalue?.value?.time }).first else {
            return nil
        }
        return WikidataAPI.parseWikidataTime(time)
    }
}

private struct WikidataLabel: Decodable {
    let value: String
}

private struct WikidataClaim: Decodable {
    let mainsnak: WikidataMainSnak
}

private struct WikidataMainSnak: Decodable {
    let datavalue: WikidataDataValue?
}

private struct WikidataDataValue: Decodable {
    let value: WikidataEntityValue?
    let stringValue: String?

    private enum CodingKeys: String, CodingKey {
        case value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        value = try? container.decode(WikidataEntityValue.self, forKey: .value)
        stringValue = try? container.decode(String.self, forKey: .value)
    }
}

private struct WikidataEntityValue: Decodable {
    let id: String?
    let time: String?
}
