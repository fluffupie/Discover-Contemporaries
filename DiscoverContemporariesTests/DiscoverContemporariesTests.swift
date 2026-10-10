//
//  DiscoverContemporariesTests.swift
//  DiscoverContemporariesTests
//
//  Created by Hengly Lim on 11/10/2026.
//

import XCTest
@testable import DiscoverContemporaries

@MainActor
final class DiscoverContemporariesTests: XCTestCase {
    // Helpers

    /// Builds a Gregorian date at midday (avoids time zone edge cases).
    private func date(_ year: Int, _ month: Int = 6, _ day: Int = 15, era: Int = 1) -> Date {
        Calendar(identifier: .gregorian).date(
            from: DateComponents(era: era, year: year, month: month, day: day, hour: 12)
        )!
    }
    
    private func makeFigure(
            id: String = "Q1",
            name: String = "Test Person",
            description: String? = nil,
            birthPlace: String? = nil,
            birth: Date? = nil,
            death: Date? = nil,
            occupations: [String] = []
    ) -> HistoricalFigure {
        HistoricalFigure(
            id: id,
            name: name,
            descriptionText: description,
            gender: nil,
            birthPlace: birthPlace,
            birthDate: birth,
            deathDate: death,
            occupations: occupations,
            movements: [],
            imageURL: nil,
            imageName: nil
        )
    }
    
    // Testing Historical Figures
    // Test 1: Lifespan text shown across the app
    func testLifespan_formatsDatesAndHandlesMissingValues() {
        let ada = date(1815, 12, 10)
        let adaDeath = date(1852, 11, 27)
        
        XCTAssertEqual(makeFigure().lifespan, "Unknown")
        XCTAssertEqual(makeFigure(birth: ada).lifespan, "10/12/1815 - Present")
        XCTAssertEqual(makeFigure(birth: ada, death: adaDeath).lifespan,
                       "10/12/1815 - 27/11/1852")
    }
    
    // Test 2: Age calculation including the "died before their birthday" case
    func testAge_isCalculatedAtDeathAndHandlesUnknown() {
        // Born 10 Dec 1815, died 27 Nov 1852: one day short of 37
        let ada = makeFigure(birth: date(1815, 12, 10), death: date(1852, 11, 27))
        XCTAssertEqual(ada.age, 36)
        XCTAssertEqual(ada.ageText, "Age 36 (at death)")
        
        let undated = makeFigure()
        XCTAssertNil(undated.age)
        XCTAssertEqual(undated.ageText, "Unknown age")
    }
    
    // Test 3: Subtitle fallback logic used in lists
    func testSubtitle_prefersDescriptionThenFallsBackToOccupationAndPlace() {
        let withDescription = makeFigure(description: "  Mathematician and writer  ")
        XCTAssertEqual(withDescription.subtitle, "Mathematician and writer")
        
        let blankDescription = makeFigure(
            description: "   ",
            birthPlace: "London",
            occupations: ["Mathematician"]
        )
        XCTAssertEqual(blankDescription.subtitle, "Mathematician • London")
        
        XCTAssertNil(makeFigure().subtitle)
    }
    
    // Test 4: Searching a figure by name, occupation, or birth place
    func testMatches_isCaseInsensitiveAcrossMultipleFields() {
        let ada = makeFigure(
            name: "Ada Lovelace",
            description: "First computer programmer",
            birthPlace: "London",
            occupations: ["Mathematician"]
        )
        XCTAssertTrue(ada.matches("LOVELACE"))
        XCTAssertTrue(ada.matches("mathematician"))
        XCTAssertTrue(ada.matches("london"))
        XCTAssertFalse(ada.matches("physicist"))
    }
    
    // Testing Timeline Entry
    // Test 5: Figures that cannot be placed on a timeline are rejected
    func testTimelineEntry_returnsNilForMissingBirthDateOrImpossibleLifespan() {
        XCTAssertNil(TimelineEntry(figure: makeFigure()))
        
        let deathBeforeBirth = makeFigure(birth: date(1900), death: date(1800))
        XCTAssertNil(TimelineEntry(figure: deathBeforeBirth))
    }
    
    // Test 6: BC dates become negative years and display correctly
    func testTimelineEntry_handlesBCYearsAndLivingFigures() throws {
        // Cleopatra: 69 BC to 30 BC (era 0 = BC)
        let cleopatra = makeFigure(
            birth: date(69, era: 0),
            death: date(30, era: 0)
        )
        let entry = try XCTUnwrap(TimelineEntry(figure: cleopatra))
        XCTAssertEqual(entry.startYear, -68)      // expected 69 BC -> 1 - 69
        XCTAssertEqual(entry.endYear, -29)        // expected 30 BC -> 1 - 30
        XCTAssertEqual(entry.yearRangeText, "69 BC – 30 BC")
        XCTAssertEqual(TimelineEntry.label(for: 0), "1 BC")
        XCTAssertEqual(TimelineEntry.label(for: 1452), "1452")
        
        let living = try XCTUnwrap(TimelineEntry(figure: makeFigure(birth: date(1990))))
        XCTAssertTrue(living.isLiving)
        XCTAssertEqual(living.yearRangeText, "1990 – Present")
    }
    
    // Testing HomeViewModel
    // Test 7: Search state: whitespace is not a query and clearing reset everything
    func testHomeViewModel_searchQueryDetectionAndClearing() {
        let model = HomeViewModel()
        XCTAssertFalse(model.hasSearchQuery)
        
        model.searchText = "   "
        XCTAssertFalse(model.hasSearchQuery, "Whitespace alone should not trigger a search")
        
        model.searchText = "Newton"
        XCTAssertTrue(model.hasSearchQuery)
        
        model.clearSearch()
        XCTAssertEqual(model.searchText, "")
        XCTAssertFalse(model.hasSearchQuery)
        XCTAssertTrue(model.searchResults.isEmpty)
        XCTAssertNil(model.errorMessage)
        XCTAssertFalse(model.isLoading)
    }
    
    // Testing TimelineViewModel
    // Test 8: Input cleaning, remove duplicate, skip undated, sorting by start year
    func testTimelineViewModel_removesDuplicatesSkipsUndatedAndSorts() {
        let ada = makeFigure(id: "Q7259", name: "Ada Lovelace",
                             birth: date(1815, 12, 10), death: date(1852, 11, 27))
        let leonardo = makeFigure(id: "Q762", name: "Leonardo da Vinci",
                                  birth: date(1452, 4, 15), death: date(1519, 5, 2))
        let undated = makeFigure(id: "Q999", name: "Mystery Person")
        
        let model = TimelineViewModel(figures: [ada, leonardo, ada, undated])
        
        XCTAssertEqual(model.entries.map(\.id), ["Q762", "Q7259"])   // sorted, no duplicate
        XCTAssertEqual(model.skippedCount, 1)                       // only the undated one
    }
    
    // Test 9: Overlapping bars must not share a row
    func testTimelineViewModel_overlappingFiguresGetSeparateRows() throws {
        let leonardo = makeFigure(id: "A", name: "Leonardo",
                                  birth: date(1452), death: date(1519))
        let babbage = makeFigure(id: "B", name: "Babbage",
                                 birth: date(1791), death: date(1871))
        let ada = makeFigure(id: "C", name: "Ada",
                             birth: date(1815), death: date(1852))
        
        let model = TimelineViewModel(figures: [leonardo, babbage, ada])
        
        let rowA = try XCTUnwrap(model.rows["A"])
        let rowB = try XCTUnwrap(model.rows["B"])
        let rowC = try XCTUnwrap(model.rows["C"])
        
        XCTAssertNotEqual(rowB, rowC, "Babbage and Ada lived at the same time")
        XCTAssertEqual(rowA, rowB, "Leonardo's bar ends long before Babbage's starts")
        XCTAssertEqual(model.rowCount, 2)
    }
    
    // Test 10: Zoom limits and selection toggling
    func testTimelineViewModel_zoomIsClampedAndSelectionToggles() throws {
        let figure = makeFigure(id: "Q1", birth: date(1800), death: date(1850))
        let model = TimelineViewModel(figures: [figure])
        
        for _ in 0..<30 { model.zoomIn() }
        XCTAssertEqual(model.pointsPerYear, TimelineViewModel.maxScale)
        
        for _ in 0..<60 { model.zoomOut() }
        XCTAssertEqual(model.pointsPerYear, TimelineViewModel.minScale)
        
        let entry = try XCTUnwrap(model.entries.first)
        model.select(entry)
        XCTAssertEqual(model.selectedID, "Q1")
        model.select(entry)                       // tapping again deselects
        XCTAssertNil(model.selectedID)
    }
}
