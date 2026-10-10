import SwiftUI

extension Color {
    static let appBackground = Color(red: 246 / 255, green: 243 / 255, blue: 238 / 255)
    static let primaryText = Color(red: 68/255, green: 66/255, blue: 64/255)
    static let secondaryText = Color(red: 0.40, green: 0.30, blue: 0.30)
    static let cardSecondaryText = Color(
        red: 64 / 255,
        green: 48 / 255,
        blue: 48 / 255
    )
    
    static let coral = Color(red: 0.70, green: 0.20, blue: 0.24)
    static let minty = Color(red: 0.72, green: 0.88, blue: 0.82)
    static let emerald = Color(
        red: 40 / 255,
        green: 118 / 255,
        blue: 111 / 255
    )
    static let peach = Color(red: 0.94, green: 0.67, blue: 0.65)
    static let lavender = Color(red: 0.76, green: 0.69, blue: 0.88)
    static let smoke = Color(red: 0.27, green: 0.27, blue: 0.26)
}

//12 pt → .caption2
// 14 pt → .caption or .footnote (.font(.caption) or .font(.footnote))
//• 16 pt → .subheadline or .callout (.font(.subheadline.weight(.semibold)))
//• 20 pt → .title3 (.font(.title3))
//• 24 pt → .title2 (.font(.title2))
//• 28 pt → .title or .largeTitle (.font(.title.weight(.semibold)) or .font(.largeTitle) )
