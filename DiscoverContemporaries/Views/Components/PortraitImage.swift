import SwiftUI

struct PortraitImage: View {
    private let imageName: String?
    private let imageURL: URL?

    init(imageName: String) {
        self.imageName = imageName
        self.imageURL = nil
    }

    init(imageURL: URL?) {
        self.imageName = nil
        self.imageURL = imageURL
    }

    var body: some View {
        Group {
            if let imageURL {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.black.opacity(0.05)
                }
            } else if let imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.black.opacity(0.05)
            }
        }
        .background(Color.black.opacity(0.05))
    }
}
