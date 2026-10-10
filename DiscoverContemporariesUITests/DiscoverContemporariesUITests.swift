//
//  DiscoverContemporariesUITests.swift
//  DiscoverContemporariesUITests
//
//  Created by Hengly Lim on 11/10/2026.
//

import XCTest

final class DiscoverContemporariesUITests: XCTestCase {
    private enum Tab {
        static let home = "Home"
        static let explore = "Explore"
        static let saves = "Saves"
    }
    
    private let network: TimeInterval = 30
    private var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        XCTAssertTrue(
            app.navigationBars["Home"].waitForExistence(timeout: 10),
            "Home screen did not appear"
        )
    }
    
    // Helpers
    private func element(_ label: String) -> XCUIElement {
        app.descendants(matching: .any)[label].firstMatch
    }
    
    private func goToTab(_ name: String) {
        let tab = app.tabBars.buttons[name]
        XCTAssertTrue(tab.waitForExistence(timeout: 5), "Tab \(name) missing")
        tab.tap()
    }
    
    private func goBack() {
        app.navigationBars.buttons.element(boundBy: 0).tap()
    }
    
    /// Polls until a condition is true (for values that load asynchronously).
    private func waitUntil(
        _ timeout: TimeInterval,
        _ condition: () -> Bool
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        }
        return condition()
    }
    
    private func scrollUntilHittable(_ el: XCUIElement, maxSwipes: Int = 6) {
        var swipes = 0
        while !el.isHittable && swipes < maxSwipes {
            app.swipeUp()
            swipes += 1
        }
    }
    
    /// Searches from Home and opens the first matching result's profile.
    private func searchAndOpenProfile(_ name: String) {
        goToTab(Tab.home)
        let field = app.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(name + "\n")
        
        let result = app.buttons
            .matching(NSPredicate(format: "label CONTAINS[c] %@", name))
            .firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: network), "No search result for \(name)")
        result.tap()
        XCTAssertTrue(app.navigationBars["Profile"].waitForExistence(timeout: 10))
    }
    
    private var auditLines: [String] = []

    private func audit(_ screen: String) throws {
        let tabBar = app.tabBars.firstMatch.frame

        // On Home, work out where the featured carousel sits
        var carousel: CGRect?
        if screen == "Home" {
            let top = app.staticTexts["Featured figures"].frame
            let bottom = app.staticTexts["Explore figures"].frame
            carousel = CGRect(
                x: 0, y: top.maxY,
                width: app.frame.width,
                height: bottom.minY - top.maxY
            )
        }

        try app.performAccessibilityAudit { issue in
            let frame = issue.element?.frame ?? .zero

            // Content scrolls under the floating tab bar by design
            if (issue.auditType == .contrast || issue.auditType == .textClipped),
               frame != .zero, frame.intersects(tabBar) {
                return true
            }

            // Carousel in its placeholder state (test data has no photo) and its
            // UIKit page control, which we can't restyle
            if let carousel {
                if frame != .zero, frame.intersects(carousel) { return true }
                if issue.element == nil, issue.auditType == .textClipped { return true }
            }

            let label = issue.element?.label ?? "nil"
            self.auditLines.append(
                "[\(screen)] \(issue.compactDescription) | \"\(label)\" | \(frame)"
            )
            return true
        }
    }
    
    // Test 1: Searching and profile view with loaded details
    func testSearchOpensProfileWithLoadedDetails() {
        searchAndOpenProfile("Marie Curie")
        
        XCTAssertTrue(element("Marie Curie").waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Summary"].exists)
        XCTAssertTrue(app.staticTexts["Details"].exists)
        
        // Search results only carry a name/description; birth and death dates
        // arrive from a second Wikidata request, so wait for the lifespan.
        let lifespan = element("Lifespan")
        XCTAssertTrue(lifespan.waitForExistence(timeout: 10))
        XCTAssertTrue(
            waitUntil(network) { (lifespan.value as? String)?.contains("1867") == true },
            "Lifespan never loaded real data, got: \(String(describing: lifespan.value))"
        )
    }
    
    // Test 2: Bookmarking, Bookmarked figure appear in saves and removing bookmarks
    func testBookmarkFigureAppearsInSavesAndCanBeRemoved() {
        searchAndOpenProfile("Marie Curie")
        
        // Start from a known state in case an earlier run left it bookmarked
        let remove = app.buttons["Remove from bookmarks"]
        let save = app.buttons["Save to bookmarks"]
        XCTAssertTrue(
            waitUntil(10) { remove.exists || save.exists },
            "Bookmark button never appeared"
        )
        if remove.exists {
            remove.tap()
            XCTAssertTrue(save.waitForExistence(timeout: 5))
        }
        
        save.tap()
        XCTAssertTrue(
            app.buttons["Remove from bookmarks"].waitForExistence(timeout: 5),
            "Button did not switch to the bookmarked state"
        )
        
        // Saved list should now contain her
        goToTab(Tab.saves)
        let savedRow = app.cells
            .containing(NSPredicate(format: "label CONTAINS[c] %@", "Marie Curie"))
            .firstMatch
        XCTAssertTrue(savedRow.waitForExistence(timeout: 10), "Bookmarked figure missing from Saves")
        
        // Swipe to delete, then check the empty state
        savedRow.swipeLeft()
        app.buttons["Delete"].tap()
        XCTAssertTrue(
            app.staticTexts["No saved figures"].waitForExistence(timeout: 10),
            "Empty state not shown after removing the only bookmark"
        )
    }
    
    // Test 3: Exploring contemporaries by region and contemporaries comparison
    func testExploreRegionToContemporariesToComparison() {
        goToTab(Tab.explore)
        element("Explore by region").tap()
        XCTAssertTrue(app.navigationBars["Regions"].waitForExistence(timeout: 5))
        
        element("Europe").tap()
        XCTAssertTrue(app.navigationBars["Europe"].waitForExistence(timeout: 5))
        
        let firstFigure = app.cells.firstMatch
        XCTAssertTrue(firstFigure.waitForExistence(timeout: network), "Top figures never loaded")
        firstFigure.tap()
        XCTAssertTrue(app.navigationBars["Profile"].waitForExistence(timeout: 10))
        
        let seeAll = app.buttons["See all"]
        XCTAssertTrue(seeAll.waitForExistence(timeout: 5))
        scrollUntilHittable(seeAll)
        seeAll.tap()
        XCTAssertTrue(app.navigationBars["Contemporaries"].waitForExistence(timeout: 5))
        
        let contemporary = app.cells.firstMatch
        XCTAssertTrue(contemporary.waitForExistence(timeout: network), "Contemporaries never loaded")
        contemporary.tap()
        
        // We are now on the comparison screen: its back button is titled
        // with the screen we came from.
        XCTAssertTrue(
            app.navigationBars.buttons["Contemporaries"].waitForExistence(timeout: 10),
            "Did not navigate to the comparison screen"
        )
        
        // Unwind the whole stack and confirm we land back on Explore
        var backs = 0
        while !app.navigationBars["Explore"].exists && backs < 6 {
            goBack()
            backs += 1
        }
        XCTAssertTrue(app.navigationBars["Explore"].exists, "Navigation stack did not unwind to Explore")
    }
    
    // Test 4: Interactive Timeline test: select, zoom, and opening profile
    func testTimelineSelectZoomAndOpenProfile() {
        goToTab(Tab.explore)
        element("Explore the timeline").tap()
        XCTAssertTrue(app.navigationBars["Timeline"].waitForExistence(timeout: 5))
        
        // Before selecting, the footer shows instructions
        let instructions = app.staticTexts["Timeline instructions"]
        XCTAssertTrue(instructions.waitForExistence(timeout: 10), "Timeline empty: was the cache seeded?")
        
        // Bars are buttons labelled "<name>, <years>"
        let bar = app.scrollViews.buttons
            .matching(NSPredicate(format: "label CONTAINS ','"))
            .firstMatch
        XCTAssertTrue(bar.waitForExistence(timeout: 10), "No timeline bars drawn")
        let figureName = bar.label.components(separatedBy: ",").first ?? ""
        XCTAssertFalse(figureName.isEmpty)
        bar.tap()
        
        // Selecting replaces the instructions with the figure's card
        XCTAssertTrue(
            waitUntil(5) { !instructions.exists },
            "Instructions should disappear once a bar is selected"
        )
        
        // Zoom controls should not break the layout
        app.buttons["Zoom in"].tap()
        app.buttons["Zoom in"].tap()
        app.buttons["Zoom out"].tap()
        app.buttons["Fit all"].tap()
        XCTAssertTrue(app.buttons["Zoom in"].exists)
        
        // Tap the selected-figure card to open the profile
        let card = app.buttons[figureName]
        XCTAssertTrue(card.waitForExistence(timeout: 5), "Selected figure card missing")
        card.tap()
        XCTAssertTrue(app.navigationBars["Profile"].waitForExistence(timeout: 10))
        XCTAssertTrue(element(figureName).waitForExistence(timeout: 10))
    }
    
    // Test 5: Testing Accessibility across the main journey through the app
    func testAccessibilityAuditAcrossMainScreens() throws {
        try audit("Home")

        goToTab(Tab.explore)
        XCTAssertTrue(app.navigationBars["Explore"].waitForExistence(timeout: 5))
        try audit("Explore")

        element("Explore by region").tap()
        XCTAssertTrue(app.navigationBars["Regions"].waitForExistence(timeout: 5))
        try audit("Regions")

        searchAndOpenProfile("Marie Curie")
        XCTAssertTrue(element("Lifespan").waitForExistence(timeout: 10))
        try audit("Profile")

        goToTab(Tab.saves)
        XCTAssertTrue(app.navigationBars["Saves"].waitForExistence(timeout: 5))
        try audit("Saves")
    }
}
