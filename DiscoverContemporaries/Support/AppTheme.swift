import SwiftUI

extension Color {
    static let appBackground = Color(red: 246 / 255, green: 243 / 255, blue: 238 / 255)
    static let primaryText = Color(red: 0.14, green: 0.13, blue: 0.12)
    static let secondaryText = Color(red: 0.50, green: 0.47, blue: 0.43)
    static let coral = Color(red: 0.84, green: 0.29, blue: 0.30)
    static let fern = Color(red: 0.25, green: 0.52, blue: 0.38)
    static let emerald = Color(red: 0.07, green: 0.46, blue: 0.35)
    static let smoke = Color(red: 0.27, green: 0.27, blue: 0.26)
    static let midnight = Color(red: 0.17, green: 0.19, blue: 0.26)
    static let ochre = Color(red: 0.65, green: 0.45, blue: 0.17)
    static let tealButton = Color(red: 0.06, green: 0.55, blue: 0.48)
    static let mintTile = Color(red: 0.62, green: 0.83, blue: 0.77)
    static let peachTile = Color(red: 0.94, green: 0.77, blue: 0.61)
    static let lavenderTile = Color(red: 0.76, green: 0.69, blue: 0.88)
    static let seaTile = Color(red: 0.45, green: 0.74, blue: 0.70)
    static let rosePanel = Color(red: 0.95, green: 0.75, blue: 0.73)
    static let mintPanel = Color(red: 0.72, green: 0.88, blue: 0.82)
    static let compareMint = Color(red: 0.55, green: 0.78, blue: 0.71)
    static let compareRed = Color(red: 0.70, green: 0.20, blue: 0.24)
    static let compareGreen = Color(red: 0.22, green: 0.62, blue: 0.52)
    static let compareGold = Color(red: 1.00, green: 0.83, blue: 0.00)
    static let comparePurple = Color(red: 0.55, green: 0.24, blue: 1.00)
}

extension Color {
    static let firstCompareGradient = AngularGradient(
        stops: [
            Gradient.Stop(color: Color(red: 0.62, green: 0.11, blue: 0.14), location: 0.35),
            Gradient.Stop(color: Color(red: 1, green: 0.67, blue: 0.54), location: 0.60),
            Gradient.Stop(color: Color(red: 0.92, green: 0.48, blue: 0.22), location: 0.72)
        ],
        center: UnitPoint(x: 0.14, y: 0.78),
        angle: Angle(degrees: -88.94)
    )
}

extension Font {
    static let h1Title = Font.title
    static let welcomeTitle = Font.custom("AlegreyaSansSC-Regular", size: 24, relativeTo: .title2)
}
extension View {
    func h1NavigationTitle(_ title: String) -> some View {
        navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(.h1Title)
                        .tracking(1.2)
                        .foregroundStyle(Color.primaryText)
                }
            }
    }
}

