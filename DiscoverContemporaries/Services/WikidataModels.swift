import Foundation

/// Contains additional Wikidata details for a historical figure.
struct WikidataFigureDetails {
    let birthDate: Date?
    let deathDate: Date?
    let portraitURL: URL?
    let birthPlaceID: String?
    let citizenshipID: String?
}

struct WikidataEntitiesResponse: Decodable {
    let entities: [String: WikidataEntity]
}

struct WikidataEntity: Decodable {
    let claims: [String: [WikidataClaim]]?
    let labels: [String: WikidataLabel]?
    let descriptions: [String: WikidataLabel]?

    var englishLabel: String? {
        labels?["en"]?.value
    }

    var englishDescription: String? {
        descriptions?["en"]?.value
    }

    var isHuman: Bool {
        claims?["P31"]?
            .contains {
                $0.mainsnak
                    .datavalue?
                    .value?
                    .id == "Q5"
            }
            ?? false
    }

    var birthPlaceIDs: [String] {
        claims?["P19"]?
            .compactMap {
                $0.mainsnak
                    .datavalue?
                    .value?
                    .id
            }
            ?? []
    }

    var citizenshipIDs: [String] {
        claims?["P27"]?
            .compactMap {
                $0.mainsnak
                    .datavalue?
                    .value?
                    .id
            }
            ?? []
    }

    var portraitFileName: String? {
        claims?["P18"]?
            .compactMap {
                $0.mainsnak
                    .datavalue?
                    .stringValue
            }
            .first
    }

    var birthDate: Date? {
        guard let time = claims?["P569"]?
            .compactMap({
                $0.mainsnak
                    .datavalue?
                    .value?
                    .time
            })
            .first
        else {
            return nil
        }

        return WikidataAPI.parseWikidataTime(
            time
        )
    }

    var deathDate: Date? {
        guard let time = claims?["P570"]?
            .compactMap({
                $0.mainsnak
                    .datavalue?
                    .value?
                    .time
            })
            .first
        else {
            return nil
        }

        return WikidataAPI.parseWikidataTime(
            time
        )
    }
}

struct WikidataLabel: Decodable {
    let value: String
}

struct WikidataClaim: Decodable {
    let mainsnak: WikidataMainSnak
}

struct WikidataMainSnak: Decodable {
    let datavalue: WikidataDataValue?
}

struct WikidataDataValue: Decodable {
    let value: WikidataEntityValue?
    let stringValue: String?

    private enum CodingKeys: String, CodingKey {
        case value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(
            keyedBy: CodingKeys.self
        )

        value = try? container.decode(
            WikidataEntityValue.self,
            forKey: .value
        )

        stringValue = try? container.decode(
            String.self,
            forKey: .value
        )
    }
}

struct WikidataEntityValue: Decodable {
    let id: String?
    let time: String?
}
