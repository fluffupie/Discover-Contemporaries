//
//  DiscoverContemporariesApp.swift
//  DiscoverContemporaries
//
//  Created by Nina Chen on 31/8/2026.
//

import CoreText
import SwiftUI

// app entry point
@main
struct DiscoverContemporariesApp: App {
    init() {
        FontRegistrar.registerFonts(in: "Alegreya_Sans_SC")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

private enum FontRegistrar {
    static func registerFonts(in folderName: String) {
        let nestedFontURLs = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: folderName) ?? []
        let rootFontURLs = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? []
        let fontURLs = (nestedFontURLs + rootFontURLs).filter { url in
            url.lastPathComponent.hasPrefix("AlegreyaSansSC-")
        }

        for fontURL in fontURLs {
            CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
        }
    }
}
