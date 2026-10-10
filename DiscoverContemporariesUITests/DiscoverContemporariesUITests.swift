//
//  DiscoverContemporariesUITests.swift
//  DiscoverContemporaries
//
//  Created by Hengly Lim on 11/10/2026.
//

import XCTest

final class DiscoverContemporariesUITests: XCTestCase {
    private enum Tab {
        static let home = "Home"
        static let explore = "Explore"
        static let saves = "Saves"
        
        private let network: TimeInterval = 30
        private var app: XCUIApplication!
        
        override func setUpWithError() throws {
            continueAfterFailure = false
            app = XCUIApplication()
            app.launch()
            // Home seeds the SwiftData cache on first load; wait for it
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
        
        
    }
}
