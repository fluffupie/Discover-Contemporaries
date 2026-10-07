import Foundation

struct WikidataAPI {

    private static func makeHistoricalFigure(
        from binding: SPARQLBinding
    ) -> HistoricalFigure? {
        guard let id = wikidataID(from: binding.person.value) else {
            return nil
        }

        return HistoricalFigure(
            id: id,
            name: binding.personLabel.value,
            descriptionText: nil,
            gender: nil,
            birthPlace: nil,
            birthDate: binding.birth.flatMap {
                parseSPARQLDate($0.value)
            },
            deathDate: binding.death.flatMap {
                parseSPARQLDate($0.value)
            },
            occupations: [],
            movements: [],
            imageURL: nil,
            imageName: nil
        )
    }

    private static func executeSPARQL(
        _ query: String,
        completion: @escaping ([SPARQLBinding]) -> Void
    ) {
        guard var components = URLComponents(string: sparqlURL) else {
            completion([])
            return
        }

        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "format", value: "json"),
        ]

        guard let url = components.url else {
            completion([])
            return
        }

        fetch(url: url, as: SPARQLResponse.self) { response in
            completion(response?.results.bindings ?? [])
        }
    }

    private static let baseURL =
        "https://www.wikidata.org/w/api.php"

    private static let sparqlURL =
        "https://query.wikidata.org/sparql"

    // MARK: - Contemporaries

    static func fetchContemporaries(
        for figure: HistoricalFigure,
        completion: @escaping ([ContemporaryFigure]) -> Void
    ) {
        guard
            let birthDate = figure.birthDate,
            let deathDate = figure.deathDate
        else {
            completion([])
            return
        }

        let calendar = Calendar(
            identifier: .gregorian
        )
        guard
            let searchStartDate = calendar.date(
                byAdding: .year,
                value: -10,
                to: birthDate
            ),
            let searchEndDate = calendar.date(
                byAdding: .year,
                value: 10,
                to: birthDate
            )
        else {
            completion([])
            return
        }

        let searchStart =
            sparqlDateFormatter.string(
                from: searchStartDate
            )

        let searchEnd =
            sparqlDateFormatter.string(
                from: searchEndDate
            )

        let query = """
            SELECT DISTINCT
                ?person
                ?personLabel
                ?birth
                ?death
                ?image
                ?sitelinks
            WHERE {
                ?person wdt:P31 wd:Q5;
                        wdt:P569 ?birth;
                        wikibase:sitelinks ?sitelinks.

                hint:Prior hint:rangeSafe true.

                FILTER(
                    "\(searchStart)T00:00:00Z"^^xsd:dateTime <= ?birth &&
                    ?birth <= "\(searchEnd)T23:59:59Z"^^xsd:dateTime
                )

                FILTER(?person != wd:\(figure.id))

                FILTER(?sitelinks >= 200)

                OPTIONAL {
                    ?person wdt:P570 ?death.
                }
            OPTIONAL {
                    ?person wdt:P18 ?image.
                }

                SERVICE wikibase:label {
                    bd:serviceParam wikibase:language "en".
                }
            }
            ORDER BY DESC(?sitelinks)
            LIMIT 20
            """

        guard
            var components = URLComponents(
                string: sparqlURL
            )
        else {
            completion([])
            return
        }

        components.queryItems = [
            URLQueryItem(
                name: "query",
                value: query
            ),
            URLQueryItem(
                name: "format",
                value: "json"
            ),
        ]

        guard let url = components.url else {
            completion([])
            return
        }

        var request = request(for: url)

        // Avoid leaving the UI waiting indefinitely.
        request.timeoutInterval = 30

        URLSession.shared.dataTask(
            with: request
        ) { data, response, error in

            if let error {
                print(
                    "Contemporaries request failed: \(error)"
                )

                Task { @MainActor in
                    completion([])
                }

                return
            }

            if let httpResponse =
                response as? HTTPURLResponse
            {

                print(
                    "Contemporaries HTTP status: \(httpResponse.statusCode)"
                )

                guard
                    (200...299).contains(
                        httpResponse.statusCode
                    )
                else {
                    Task { @MainActor in
                        completion([])
                    }

                    return
                }
            }

            guard let data else {
                print(
                    "Contemporaries request returned no data."
                )

                Task { @MainActor in
                    completion([])
                }

                return
            }

            Task { @MainActor in
                do {
                    let response =
                        try JSONDecoder().decode(
                            SPARQLResponse.self,
                            from: data
                        )
                    
                    let contemporaries =
                        response.results.bindings
                            .compactMap { binding -> ContemporaryFigure? in
                                makeContemporary(
                                    from: binding,
                                    targetBirthDate: birthDate,
                                    targetDeathDate: deathDate
                                )
                            }

                    let uniqueContemporaries =
                        removeDuplicateContemporaries(
                            from: contemporaries
                        )

                    completion(
                        Array(
                            uniqueContemporaries.prefix(20)
                        )
                    )

                    print(
                        "Found \(contemporaries.count) contemporaries for \(figure.name)"
                    )

                    completion(
                        Array(
                            contemporaries.prefix(20)
                        )
                    )

                } catch {
                    print(
                        "Failed to decode contemporaries: \(error)"
                    )

                    if let responseText = String(
                        data: data,
                        encoding: .utf8
                    ) {
                        print(
                            "SPARQL response: \(responseText.prefix(500))"
                        )
                    }

                    completion([])
                }
            }
        }
        .resume()
    }
    
    private static func removeDuplicateContemporaries(
        from figures: [ContemporaryFigure]
    ) -> [ContemporaryFigure] {
        var seenIDs = Set<String>()

        return figures.filter { figure in
            seenIDs.insert(figure.id).inserted
        }
    }

    private static func makeContemporary(
        from binding: SPARQLBinding,
        targetBirthDate: Date,
        targetDeathDate: Date
    ) -> ContemporaryFigure? {
        guard
            let id = wikidataID(
                from: binding.person.value
            ),
            let candidateBirth = binding.birth.flatMap({
                parseSPARQLDate($0.value)
            })
        else {
            return nil
        }

        let candidateDeath = binding.death.flatMap {
            parseSPARQLDate($0.value)
        }

        let candidateEnd = candidateDeath ?? Date()

        let overlaps =
            candidateBirth <= targetDeathDate && candidateEnd >= targetBirthDate

        guard overlaps else {
            return nil
        }

        return ContemporaryFigure(
            id: id,
            name: binding.personLabel.value,
            birthDate: candidateBirth,
            deathDate: candidateDeath,
            imageURL: binding.image.flatMap {
                URL(string: $0.value)
            }
        )
    }

    private static func wikidataID(
        from uri: String
    ) -> String? {
        URL(string: uri)?
            .lastPathComponent
    }

    private static func parseSPARQLDate(
        _ value: String
    ) -> Date? {
        ISO8601DateFormatter().date(
            from: value
        )
    }

    private static let sparqlDateFormatter: DateFormatter = {
        let formatter = DateFormatter()

        formatter.locale = Locale(
            identifier: "en_US_POSIX"
        )

        formatter.calendar = Calendar(
            identifier: .gregorian
        )

        formatter.dateFormat = "yyyy-MM-dd"

        return formatter
    }()

    // MARK: - Continent Top Figures
    static func fetchTopFigures(
        forContinentID id: String,
        completion: @escaping ([HistoricalFigure]) -> Void
    ) {
        let query = """
            SELECT DISTINCT
                ?person
                ?personLabel
                ?birth
                ?death
                ?sitelinks
            WHERE {
                VALUES ?continent { wd:\(id) }

                ?person wdt:P31 wd:Q5 ;
                        wikibase:sitelinks ?sitelinks .

                FILTER(?sitelinks >= 150)

                OPTIONAL { ?person wdt:P569 ?birth. }
                OPTIONAL { ?person wdt:P570 ?death. }

                {
                    # Primary filter:
                    # Use country of citizenship (P27)
                    ?person wdt:P27 ?country .
                    ?country wdt:P30 ?continent .
                }
                UNION
                {
                    # Fallback:
                    # Only use birthplace when P27 is completely missing
                    FILTER NOT EXISTS {
                        ?person wdt:P27 ?anyCountry .
                    }

                    ?person wdt:P19 ?birthPlace .
                    ?birthPlace wdt:P17 ?country .
                    ?country wdt:P30 ?continent .
                }

                SERVICE wikibase:label {
                    bd:serviceParam wikibase:language "en".
                }
            }
            ORDER BY DESC(?sitelinks)
            LIMIT 10
            """

        executeSPARQL(query) { bindings in
            let figures = bindings.compactMap(makeHistoricalFigure)
            completion(figures)
        }
    }

    // MARK: - Occupation Top Figures

    static func fetchTopFigures(
        forOccupationID id: String,
        completion: @escaping ([HistoricalFigure]) -> Void
    ) {
        let query = """
            SELECT DISTINCT ?person ?personLabel ?birth ?death ?sitelinks WHERE {
              ?person wdt:P31 wd:Q5 ;
                      wikibase:sitelinks ?sitelinks ;
                      wdt:P106 ?occ .

              # Include subclasses of the requested occupation
              ?occ wdt:P279* wd:\(id) .

              FILTER(?sitelinks >= 200)

              OPTIONAL { ?person wdt:P569 ?birth. }
              OPTIONAL { ?person wdt:P570 ?death. }

              hint:Prior hint:rangeSafe true.

              SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
            }
            ORDER BY DESC(?sitelinks)
            LIMIT 20
            """

        executeSPARQL(query) { bindings in
            let figures = bindings.compactMap(makeHistoricalFigure)
            completion(figures)
        }
    }

    // MARK: - Figure Search

    static func fetchFigures(
        query: String,
        completion: @escaping ([WikidataSearchResult]) -> Void
    ) {
        guard
            let url = makeSearchURL(
                query: query
            )
        else {
            completion([])
            return
        }

        fetch(
            url: url,
            as: WikidataSearchResponse.self
        ) { response in

            guard let response else {
                completion([])
                return
            }

            filterHumanResults(
                response.search,
                completion: completion
            )
        }
    }

    // MARK: - Figure Details

    static func fetchDetails(
        forID id: String,
        completion: @escaping (WikidataFigureDetails?) -> Void
    ) {
        guard
            let url = makeEntitiesURL(
                ids: [id],
                properties: "claims"
            )
        else {
            completion(nil)
            return
        }

        fetch(
            url: url,
            as: WikidataEntitiesResponse.self
        ) { response in

            guard
                let entity =
                    response?.entities[id]
            else {
                completion(nil)
                return
            }

            let details =
                WikidataFigureDetails(
                    birthDate:
                        entity.birthDate,

                    deathDate:
                        entity.deathDate,

                    portraitURL:
                        entity.portraitFileName
                        .flatMap(
                            commonsImageURL
                        ),

                    countryID:
                        entity.countryIDs.first
                )

            completion(details)
        }
    }

    // MARK: - Country

    static func fetchCountryName(
        forID id: String,
        completion: @escaping (String?) -> Void
    ) {
        fetchDetails(
            forID: id
        ) { details in

            guard
                let countryID =
                    details?.countryID
            else {
                completion(nil)
                return
            }

            fetchEntityLabel(
                forID: countryID,
                completion: completion
            )
        }
    }

    // MARK: - Entity Label

    static func fetchEntityLabel(
        forID id: String,
        completion: @escaping (String?) -> Void
    ) {
        guard
            let url = makeEntitiesURL(
                ids: [id],
                properties: "labels",
                languages: "en"
            )
        else {
            completion(nil)
            return
        }

        fetch(
            url: url,
            as: WikidataEntitiesResponse.self
        ) { response in

            completion(
                response?
                    .entities[id]?
                    .englishLabel
            )
        }
    }

    // MARK: - Human Filtering

    private static func filterHumanResults(
        _ results: [WikidataSearchResult],
        completion: @escaping ([WikidataSearchResult]) -> Void
    ) {
        let ids = results.map(\.id)

        guard !ids.isEmpty else {
            completion([])
            return
        }

        guard
            let url = makeEntitiesURL(
                ids: ids,
                properties: "claims"
            )
        else {
            completion([])
            return
        }

        fetch(
            url: url,
            as: WikidataEntitiesResponse.self
        ) { response in

            guard let response else {
                completion([])
                return
            }

            let humanIDs = Set(
                response.entities
                    .filter {
                        $0.value.isHuman
                    }
                    .map(\.key)
            )

            let humanResults =
                results.filter {
                    humanIDs.contains(
                        $0.id
                    )
                }

            completion(humanResults)
        }
    }

    // MARK: - Generic Networking

    private static func fetch<T: Decodable>(
        url: URL,
        as type: T.Type,
        completion: @escaping (T?) -> Void
    ) {
        URLSession.shared
            .dataTask(
                with: request(for: url)
            ) { data, response, error in

                if let error {
                    print(
                        "Wikidata request failed: \(error)"
                    )

                    Task { @MainActor in
                        completion(nil)
                    }

                    return
                }

                if let httpResponse =
                    response as? HTTPURLResponse
                {

                    guard
                        (200...299)
                            .contains(
                                httpResponse.statusCode
                            )
                    else {
                        print(
                            "Wikidata HTTP error: \(httpResponse.statusCode)"
                        )

                        Task { @MainActor in
                            completion(nil)
                        }

                        return
                    }
                }

                guard let data else {
                    Task { @MainActor in
                        completion(nil)
                    }

                    return
                }

                do {
                    let decoded =
                        try JSONDecoder().decode(
                            T.self,
                            from: data
                        )

                    Task { @MainActor in
                        completion(decoded)
                    }

                } catch {
                    print(
                        "Wikidata decoding failed: \(error)"
                    )

                    Task { @MainActor in
                        completion(nil)
                    }
                }
            }
            .resume()
    }

    // MARK: - URL Construction

    private static func makeSearchURL(
        query: String
    ) -> URL? {
        var components =
            URLComponents(
                string: baseURL
            )

        components?.queryItems = [
            URLQueryItem(
                name: "action",
                value: "wbsearchentities"
            ),

            URLQueryItem(
                name: "search",
                value: query
            ),

            URLQueryItem(
                name: "language",
                value: "en"
            ),

            URLQueryItem(
                name: "format",
                value: "json"
            ),

            URLQueryItem(
                name: "type",
                value: "item"
            ),

            URLQueryItem(
                name: "limit",
                value: "20"
            ),
        ]

        return components?.url
    }

    private static func makeEntitiesURL(
        ids: [String],
        properties: String,
        languages: String? = nil
    ) -> URL? {
        var components =
            URLComponents(
                string: baseURL
            )

        var queryItems = [
            URLQueryItem(
                name: "action",
                value: "wbgetentities"
            ),

            URLQueryItem(
                name: "ids",
                value:
                    ids.joined(
                        separator: "|"
                    )
            ),

            URLQueryItem(
                name: "props",
                value: properties
            ),

            URLQueryItem(
                name: "format",
                value: "json"
            ),
        ]

        if let languages {
            queryItems.append(
                URLQueryItem(
                    name: "languages",
                    value: languages
                )
            )
        }

        components?.queryItems =
            queryItems

        return components?.url
    }

    private static func request(
        for url: URL
    ) -> URLRequest {
        var request =
            URLRequest(url: url)

        request.setValue(
            "DiscoverContemporaries/1.0 (student project)",
            forHTTPHeaderField:
                "User-Agent"
        )

        request.setValue(
            "application/json",
            forHTTPHeaderField:
                "Accept"
        )

        return request
    }

    // MARK: - Wikimedia Image

    nonisolated private static func commonsImageURL(
        for fileName: String
    ) -> URL? {
        guard
            let encodedFileName =
                fileName.addingPercentEncoding(
                    withAllowedCharacters:
                        .urlPathAllowed
                )
        else {
            return nil
        }

        return URL(
            string:
                "https://commons.wikimedia.org/wiki/Special:FilePath/\(encodedFileName)?width=500"
        )
    }

    // MARK: - Wikidata Date Parsing

    fileprivate static func parseWikidataTime(
        _ time: String
    ) -> Date? {
        let trimmed =
            time.hasPrefix("+")
            ? String(
                time.dropFirst()
            )
            : time

        guard
            let datePart =
                trimmed
                .split(
                    separator: "T"
                )
                .first
        else {
            return nil
        }

        return wikidataDateFormatter.date(
            from: String(datePart)
        )
    }

    private static let wikidataDateFormatter: DateFormatter = {
        let formatter =
            DateFormatter()

        formatter.locale =
            Locale(
                identifier:
                    "en_US_POSIX"
            )

        formatter.calendar =
            Calendar(
                identifier:
                    .gregorian
            )

        formatter.dateFormat =
            "yyyy-MM-dd"

        return formatter
    }()
}

// MARK: - Figure Details

struct WikidataFigureDetails {
    let birthDate: Date?
    let deathDate: Date?
    let portraitURL: URL?
    let countryID: String?
}

// MARK: - Wikidata Entity Response

private struct WikidataEntitiesResponse: Decodable {
    let entities: [String: WikidataEntity]
}

private struct WikidataEntity: Decodable {

    let claims: [String: [WikidataClaim]]?

    let labels: [String: WikidataLabel]?

    var isHuman: Bool {
        claims?["P31"]?
            .contains { claim in
                claim
                    .mainsnak
                    .datavalue?
                    .value?
                    .id == "Q5"
            }
            ?? false
    }

    var countryIDs: [String] {
        claims?["P27"]?
            .compactMap { claim in
                claim
                    .mainsnak
                    .datavalue?
                    .value?
                    .id
            }
            ?? []
    }

    var englishLabel: String? {
        labels?["en"]?.value
    }

    var portraitFileName: String? {
        claims?["P18"]?
            .compactMap { claim in
                claim
                    .mainsnak
                    .datavalue?
                    .stringValue
            }
            .first
    }

    var birthDate: Date? {
        guard
            let time =
                claims?["P569"]?
                .compactMap({
                    $0
                        .mainsnak
                        .datavalue?
                        .value?
                        .time
                })
                .first
        else {
            return nil
        }

        return
            WikidataAPI
            .parseWikidataTime(
                time
            )
    }

    var deathDate: Date? {
        guard
            let time =
                claims?["P570"]?
                .compactMap({
                    $0
                        .mainsnak
                        .datavalue?
                        .value?
                        .time
                })
                .first
        else {
            return nil
        }

        return
            WikidataAPI
            .parseWikidataTime(
                time
            )
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

    private enum CodingKeys:
        String,
        CodingKey
    {

        case value
    }

    init(
        from decoder: Decoder
    ) throws {
        let container =
            try decoder.container(
                keyedBy:
                    CodingKeys.self
            )

        value =
            try? container.decode(
                WikidataEntityValue.self,
                forKey: .value
            )

        stringValue =
            try? container.decode(
                String.self,
                forKey: .value
            )
    }
}

private struct WikidataEntityValue: Decodable {
    let id: String?
    let time: String?
}

// MARK: - SPARQL Response

private struct SPARQLResponse: Decodable {
    let results: SPARQLResults
}

private struct SPARQLResults: Decodable {
    let bindings: [SPARQLBinding]
}

private struct SPARQLBinding: Decodable {
    let person: SPARQLValue
    let personLabel: SPARQLValue
    let birth: SPARQLValue?
    let death: SPARQLValue?
    let image: SPARQLValue?
}

private struct SPARQLValue: Decodable {
    let value: String
}
