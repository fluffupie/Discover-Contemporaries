// MARK: - Occupation Figure Seeds
/// Curated Wikidata figure IDs for each supported occupation.
enum OccupationFigureSeeds {

    /// Returns the seeded figure IDs for an occupation's Wikidata ID.
    ///
    /// - Parameter occupationID: The occupation's Wikidata ID, for example `"Q901"`.
    /// - Returns: The figure IDs, or an empty array for an unknown occupation.
    static func ids(for occupationID: String) -> [String] {
        idsByOccupation[occupationID] ?? []
    }

    /// Every seeded figure ID across all occupations, without duplicates,
    /// in the order the occupations are listed.
    static let allIDs: [String] = uniqueIDs(groups.flatMap(\.ids))
    
    /// The single source of truth for the occupation-to-figure mapping.
    private static let groups: [(occupationID: String, ids: [String])] = [
        ("Q82955", politicians),
        ("Q901", scientists),
        ("Q483501", artists),
        ("Q639669", musicians),
        ("Q33999", actors),
        ("Q177220", singers),
        ("Q11696", monarchs),
    ]

    private static let idsByOccupation: [String: [String]] = Dictionary(
        uniqueKeysWithValues: groups.map { ($0.occupationID, $0.ids) }
    )

    private static func uniqueIDs(_ ids: [String]) -> [String] {
        var seen = Set<String>()
        return ids.filter { seen.insert($0).inserted }
    }

    // MARK: - Politicians

    private static let politicians: [String] = [
        "Q76",  // Barack Obama
        "Q8016",  // Winston Churchill
        "Q8023",  // Nelson Mandela
        "Q91",  // Abraham Lincoln
        "Q567",  // Angela Merkel
        "Q7416",  // Che Guevara
        "Q8007",  // Franklin D. Roosevelt
        "Q9696",  // John F. Kennedy
        "Q1001",  // Mahatma Gandhi
        "Q8605",  // Simón Bolívar
    ]

    // MARK: - Scientists

    private static let scientists: [String] = [
        "Q937",  // Albert Einstein
        "Q935",  // Isaac Newton
        "Q7186",  // Marie Curie
        "Q1035",  // Charles Darwin
        "Q307",  // Galileo Galilei
        "Q17714",  // Stephen Hawking
        "Q9036",  // Nikola Tesla
        "Q52929",  // Louis Pasteur
        "Q7251",  // Alan Turing
        "Q7474",  // Rosalind Franklin
    ]

    // MARK: - Artists

    private static let artists: [String] = [
        "Q762",  // Leonardo da Vinci
        "Q5582",  // Vincent van Gogh
        "Q5593",  // Pablo Picasso
        "Q5592",  // Michelangelo
        "Q5588",  // Frida Kahlo
        "Q5577",  // Salvador Dalí
        "Q296",  // Claude Monet
        "Q5598",  // Rembrandt
        "Q5603",  // Andy Warhol
        "Q464744",  // Georgia O'Keeffe
    ]

    // MARK: - Musicians

    private static let musicians: [String] = [
        "Q255",  // Ludwig van Beethoven
        "Q254",  // Wolfgang Amadeus Mozart
        "Q1339",  // Johann Sebastian Bach
        "Q1268",  // Frédéric Chopin
        "Q7312",  // Pyotr Ilyich Tchaikovsky
        "Q1779",  // Louis Armstrong
        "Q93341",  // Duke Ellington
        "Q5383",  // David Bowie
        "Q7542",  // Prince
        "Q15869",  // Freddie Mercury
    ]

    // MARK: - Actors

    private static let actors: [String] = [
        "Q882",  // Charlie Chaplin
        "Q4616",  // Marilyn Monroe
        "Q4277",  // Audrey Hepburn
        "Q34012",  // Marlon Brando
        "Q873",  // Meryl Streep
        "Q2263",  // Tom Hanks
        "Q42101",  // Denzel Washington
        "Q5043",  // Cate Blanchett
        "Q10992",  // Toshiro Mifune
        "Q40572",  // Heath Ledger
    ]

    // MARK: - Singers

    private static let singers: [String] = [
        "Q2831",  // Michael Jackson
        "Q303",  // Elvis Presley
        "Q34389",  // Whitney Houston
        "Q126505",  // Aretha Franklin
        "Q15869",  // Freddie Mercury
        "Q40912",  // Frank Sinatra
        "Q1744",  // Madonna
        "Q36153",  // Beyoncé
        "Q23215",  // Adele
        "Q5105",  // Céline Dion
    ]

    // MARK: - Monarchs

    private static let monarchs: [String] = [
        "Q9682",  // Elizabeth II
        "Q7207",  // Elizabeth I
        "Q9439",  // Queen Victoria
        "Q7742",  // Louis XIV
        "Q38370",  // Henry VIII
        "Q159669",  // Catherine the Great
        "Q8479",  // Peter the Great
        "Q5879",  // Akbar
        "Q7192",  // Qin Shi Huang
        "Q176622",  // Tutankhamun
    ]
}

enum FeaturedFigureSeeds {

    static let ids: [String] = [
        "Q635",  // Cleopatra VII
        "Q1696",  // Wu Zetian
        "Q762",  // Leonardo da Vinci
        "Q7207",  // Elizabeth I
        "Q7186",  // Marie Curie
    ]
}
