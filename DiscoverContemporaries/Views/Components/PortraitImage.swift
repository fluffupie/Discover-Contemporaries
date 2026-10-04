import SwiftUI

struct PortraitImage: View {
    let imageName: String?
    let imageURL: URL?
    
    init(imageName: String? = nil, imageURL: URL? = nil) {
        self.imageName = imageName
        self.imageURL = imageURL
    }

    var body: some View {
        Group {
            if let name = imageName, !name.isEmpty, UIImage(named: name) != nil {
                Image(name)
                    .resizable()
                    .scaledToFill()
            } else if let url = imageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        placeholder(spinning: true)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholder(spinning: false)
                    @unknown default:
                        placeholder(spinning: false)
                    }
                }
            } else {
                placeholder(spinning: false)
            }
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isImage)
        .clipped()
        .background(Color.black.opacity(0.05))
    }

    private func placeholder(spinning: Bool) -> some View {
        ZStack {
            Color.gray.opacity(0.12)
            Image(systemName: "person.crop.square")
                .font(.system(size: 36, weight: .regular))
                .foregroundStyle(.secondary)
            if spinning {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.secondary)
            }
        }
    }

    private var accessibilityLabel: String {
        if let name = imageName, !name.isEmpty {
            return "Portrait image for \(name)"
        }
        return "Portrait image"
    }
}

#Preview {
    VStack(spacing: 20) {
        PortraitImage(imageName: "da-vinci", imageURL: nil)
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 10))

        PortraitImage(imageName: nil, imageURL: URL(string: "https://example.com/portrait.jpg"))
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 10))

        PortraitImage(imageName: nil, imageURL: nil)
            .frame(width: 120, height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    .padding()
}
