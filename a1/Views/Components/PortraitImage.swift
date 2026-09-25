import SwiftUI

struct PortraitImage: View {
    let imageName: String

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFill()
            .background(Color.black.opacity(0.05))
    }
}
