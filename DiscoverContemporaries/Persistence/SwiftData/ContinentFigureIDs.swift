import Foundation

/// Curated Wikidata figure IDs for each supported continent.
enum ContinentFigureIDs {
    
    /// - Parameter continentID: The Wikidata ID of the continent
    ///
    /// - Returns: An array of seeded Wikidata figure IDs for the specified continent, or an empty array if the continent is not supported.
    static func ids(for continentID: String) -> [String] {
        idsByContinent[continentID] ?? []
    }

    /// All seeded historical figure IDs across all continents, without duplicates
    static let allIDs: [String] = uniqueIDs(groups.flatMap(\.ids))

    // MARK: - Continent Lookup

    /// The single source of truth (``groups``) for the continent-to-figure mapping.
    private static let groups: [(continentID: String, ids: [String])] = [
        ("Q15", africa),
        ("Q48", asia),
        ("Q46", europe),
        ("Q828", americas),
        ("Q538", oceania),
    ]

    /// A dictionary for looking up figure IDs by continent.
    private static let idsByContinent: [String: [String]] = Dictionary(
        uniqueKeysWithValues: groups.map { ($0.continentID, $0.ids) }
    )

    /// A helper that removes duplicate Wikidata IDs from an array.
    /// Uses a set to track previously encountered IDs
    ///
    /// - Parameter ids: An array of Wikidata figure IDs.
    ///
    /// - Returns: An array containing only the first occurrence of each unique ID.
    private static func uniqueIDs(_ ids: [String]) -> [String] {
        var seen = Set<String>()
        return ids.filter { seen.insert($0).inserted }
    }

    // MARK: - Africa

    private static let africa: [String] = [
        "Q8023",  // Nelson Mandela
        "Q635",  // Cleopatra VII
        "Q12154",  // Tutankhamun
        "Q1523",  // Ramesses II
        "Q40930",  // Nefertiti
        "Q1254",  // Kofi Annan
        "Q43033",  // Desmond Tutu
        "Q41178",  // Haile Selassie
        "Q155845",  // Chinua Achebe
        "Q41488",  // Wole Soyinka
        "Q146256",  // Miriam Makeba
        "Q313868",  // Fela Kuti
        "Q8620",  // Kwame Nkrumah
        "Q309333",  // Mansa Musa
        "Q27695",  // Shaka Zulu
        "Q214473",  // Steve Biko
        "Q1354960",  // Mohamed Salah
        "Q48892",  // Didier Drogba
        "Q1255625",  // Samuel Eto'o
        "Q80046",  // Charlize Theron
    ]

    // MARK: - Asia

    private static let asia: [String] = [
        "Q1001",  // Mahatma Gandhi
        "Q4604",  // Confucius
        "Q720",  // Genghis Khan
        "Q5816",  // Mao Zedong
        "Q7192",  // Qin Shi Huang
        "Q9441",  // Gautama Buddha
        "Q9458",  // Muhammad
        "Q8006",  // Akira Kurosawa
        "Q16397",  // Bruce Lee
        "Q55400",  // Hayao Miyazaki
        "Q7241",  // Rabindranath Tagore
        "Q30547",  // Mother Teresa
        "Q17293",  // 14th Dalai Lama
        "Q9738",  // Wu Zetian
        "Q36014",  // Ho Chi Minh
        "Q131248",  // Lee Kuan Yew
        "Q16574",  // Chiang Kai-shek
        "Q36740",  // Aung San Suu Kyi
        "Q8573",  // Sun Yat-sen
        "Q1316",  // Saddam Hussein
    ]

    // MARK: - Europe

    private static let europe: [String] = [
        "Q762",  // Leonardo da Vinci
        "Q692",  // William Shakespeare
        "Q935",  // Isaac Newton
        "Q937",  // Albert Einstein
        "Q7186",  // Marie Curie
        "Q517",  // Napoleon Bonaparte
        "Q255",  // Ludwig van Beethoven
        "Q254",  // Wolfgang Amadeus Mozart
        "Q5582",  // Vincent van Gogh
        "Q5593",  // Pablo Picasso
        "Q1035",  // Charles Darwin
        "Q307",  // Galileo Galilei
        "Q5592",  // Michelangelo
        "Q1339",  // Johann Sebastian Bach
        "Q7207",  // Elizabeth I
        "Q8016",  // Winston Churchill
        "Q1048",  // Julius Caesar
        "Q8409",  // Alexander the Great
        "Q9036",  // Nikola Tesla
        "Q7259",  // Ada Lovelace
    ]

    // MARK: - Americas

    private static let americas: [String] = [
        "Q23",  // George Washington
        "Q91",  // Abraham Lincoln
        "Q8027",  // Martin Luther King Jr.
        "Q8007",  // Franklin D. Roosevelt
        "Q9696",  // John F. Kennedy
        "Q34969",  // Benjamin Franklin
        "Q7245",  // Mark Twain
        "Q23434",  // Ernest Hemingway
        "Q303",  // Elvis Presley
        "Q2831",  // Michael Jackson
        "Q5588",  // Frida Kahlo
        "Q8605",  // Simón Bolívar
        "Q5809",  // Che Guevara
        "Q12897",  // Pelé
        "Q17515",  // Diego Maradona
        "Q5878",  // Gabriel García Márquez
        "Q909",  // Jorge Luis Borges
        "Q34189",  // Pablo Neruda
        "Q10490",  // Ayrton Senna
        "Q615",  // Lionel Messi
    ]

    // MARK: - Oceania

    private static let oceania: [String] = [
        "Q21456668",  // James Cook
        "Q33817",  // Edmund Hillary
        "Q126513",  // Steve Irwin
        "Q4465",  // Peter Jackson
        "Q80966",  // Cate Blanchett
        "Q129591",  // Hugh Jackman
        "Q37459",  // Nicole Kidman
        "Q129817",  // Russell Crowe
        "Q2388576",  // Taika Waititi
        "Q3606816",  // Jacinda Ardern
        "Q11998",  // Kylie Minogue
        "Q40572",  // Heath Ledger
        "Q54314",  // Chris Hemsworth
        "Q1924847",  // Margot Robbie
        "Q13476175",  // Lorde
        "Q181484",  // Sia
    ]
}
