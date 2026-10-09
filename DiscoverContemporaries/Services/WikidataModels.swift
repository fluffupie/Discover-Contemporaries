import Foundation

/// Contains additional Wikidata details for a historical figure.
struct WikidataFigureDetails {
    let birthDate: Date?
    let deathDate: Date?
    let portraitURL: URL?
    let birthPlaceID: String?
    let citizenshipID: String?
}

/// Represents the decoded entity response returned by Wikidata.
struct WikidataEntitiesResponse: Decodable {
    let entities: [String: WikidataEntity]
}

/// Represents a Wikidata entity and its claims, labels, and descriptions.
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

/// Represents a localized Wikidata label value.
struct WikidataLabel: Decodable {
    let value: String
}

/// Represents a single Wikidata claim.
struct WikidataClaim: Decodable {
    let mainsnak: WikidataMainSnak
}

/// Represents the main statement value of a Wikidata claim.
struct WikidataMainSnak: Decodable {
    let datavalue: WikidataDataValue?
}

/// Decodes a Wikidata data value that may contain either structured or string data.
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

/// Represents structured entity data contained within a Wikidata claim value.
struct WikidataEntityValue: Decodable {
    let id: String?
    let time: String?
}
