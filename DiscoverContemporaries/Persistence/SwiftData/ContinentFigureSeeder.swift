import Foundation

enum ContinentFigureSeeds {

    static func ids(
        for continentID: String
    ) -> [String] {
        figureIDs[continentID] ?? []
    }

    // MARK: - Continent Lookup

    private static let figureIDs: [String: [String]] = [
        "Q15": africa,
        "Q48": asia,
        "Q46": europe,
        "Q828": americas,
        "Q538": oceania
    ]

    // MARK: - Africa

    private static let africa: [String] = [
        "Q8023",    // Nelson Mandela
        "Q635",     // Cleopatra
        "Q176622",  // Tutankhamun
        "Q1523",    // Ramesses II
        "Q15722",   // Nefertiti
        "Q1254",    // Kofi Annan
        "Q181444",  // Desmond Tutu
        "Q137453",  // Haile Selassie
        "Q171509",  // Chinua Achebe
        "Q186681",  // Wole Soyinka
        "Q193281",  // Miriam Makeba
        "Q213959",  // Fela Kuti
        "Q8623",    // Kwame Nkrumah
        "Q37079",   // Mansa Musa
        "Q202725",  // Shaka Zulu
        "Q217219",  // Steve Biko
        "Q1351892", // Mohamed Salah
        "Q171322",  // Didier Drogba
        "Q191145",  // Samuel Eto'o
        "Q40096"    // Charlize Theron
    ]

    // MARK: - Asia

    private static let asia: [String] = [
        "Q1001",    // Mahatma Gandhi
        "Q4604",    // Confucius
        "Q720",     // Genghis Khan
        "Q5816",    // Mao Zedong
        "Q7192",    // Qin Shi Huang
        "Q9441",    // Gautama Buddha
        "Q9458",    // Muhammad
        "Q8006",    // Akira Kurosawa
        "Q16397",   // Bruce Lee
        "Q55400",   // Hayao Miyazaki
        "Q7241",    // Rabindranath Tagore
        "Q30547",   // Mother Teresa
        "Q17293",   // 14th Dalai Lama
        "Q132002",  // Hirohito
        "Q36014",   // Ho Chi Minh
        "Q132403",  // Indira Gandhi
        "Q48340",   // Jackie Chan
        "Q36740",   // Aung San Suu Kyi
        "Q8587",    // Saladin
        "Q1316"     // Saddam Hussein
    ]

    // MARK: - Europe

    private static let europe: [String] = [
        "Q762",   // Leonardo da Vinci
        "Q692",   // William Shakespeare
        "Q935",   // Isaac Newton
        "Q937",   // Albert Einstein
        "Q7186",  // Marie Curie
        "Q517",   // Napoleon
        "Q255",   // Ludwig van Beethoven
        "Q254",   // Wolfgang Amadeus Mozart
        "Q5582",  // Vincent van Gogh
        "Q5593",  // Pablo Picasso
        "Q1035",  // Charles Darwin
        "Q307",   // Galileo Galilei
        "Q5592",  // Michelangelo
        "Q1339",  // Johann Sebastian Bach
        "Q7207",  // Elizabeth I
        "Q8016",  // Winston Churchill
        "Q1048",  // Julius Caesar
        "Q8409",  // Alexander the Great
        "Q9036",  // Nikola Tesla
        "Q7259"   // Ada Lovelace
    ]

    // MARK: - Americas

    private static let americas: [String] = [
        "Q23",      // George Washington
        "Q91",      // Abraham Lincoln
        "Q8027",    // Martin Luther King Jr.
        "Q8007",    // Franklin D. Roosevelt
        "Q9696",    // John F. Kennedy
        "Q34969",   // Benjamin Franklin
        "Q7245",    // Mark Twain
        "Q23434",   // Ernest Hemingway
        "Q303",     // Elvis Presley
        "Q2831",    // Michael Jackson
        "Q5588",    // Frida Kahlo
        "Q8605",    // Simón Bolívar
        "Q7416",    // Che Guevara
        "Q8341",    // Pelé
        "Q17515",   // Diego Maradona
        "Q5878",    // Gabriel García Márquez
        "Q909",     // Jorge Luis Borges
        "Q279454",  // Pablo Neruda
        "Q10520",   // Ayrton Senna
        "Q615"      // Lionel Messi
    ]

    // MARK: - Oceania

    private static let oceania: [String] = [
        "Q7322",     // James Cook
        "Q35589",    // Edmund Hillary
        "Q213854",   // Steve Irwin
        "Q4467",     // Peter Jackson
        "Q5043",     // Cate Blanchett
        "Q129591",   // Hugh Jackman
        "Q37459",    // Nicole Kidman
        "Q2052",     // Russell Crowe
        "Q372868",   // Taika Waititi
        "Q233949",   // Jacinda Ardern
        "Q11975",    // Kylie Minogue
        "Q40572",    // Heath Ledger
        "Q54314",    // Chris Hemsworth
        "Q192682",   // Margot Robbie
        "Q2291862",  // Lorde
        "Q154535",   // Sia
        "Q231961",   // Cathy Freeman
        "Q313876",   // Donald Bradman
        "Q215190",   // Ned Kelly
        "Q117311"    // David Unaipon
    ]

    // MARK: - Antarctica

    private static let antarctica: [String] = [
        // Likely fewer than 20
    ]
}
