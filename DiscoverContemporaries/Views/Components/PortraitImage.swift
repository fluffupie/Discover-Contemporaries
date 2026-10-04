import SwiftUI

struct PortraitImage: View {
    let imageName: String?
    let imageURL: URL?

    init(
        imageName: String? = nil,
        imageURL: URL? = nil
    ) {
        self.imageName = imageName
        self.imageURL = imageURL
    }

    var body: some View {
        Group {
            if let imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFill()

            } else if let imageURL {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    ProgressView()
                }
            } else {
                Image(systemName: "person.crop.square")
                    .resizable()
                    .scaledToFit()
            }
        }
        .clipped()
        .background(Color.black.opacity(0.05))
    }
}
