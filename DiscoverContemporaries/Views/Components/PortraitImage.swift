import SwiftUI

/// Displays a historical figure portrait using a local image, remote URL, or fallback placeholder.
struct PortraitImage: View {
    let imageName: String?
    let imageURL: URL?

    /// Creates a portrait image with optional local and remote image sources.
    ///
    /// A valid local image is preferred over the remote image URL.
    ///
    /// - Parameters:
    ///   - imageName: The name of a local image asset.
    ///   - imageURL: The remote image URL used when no valid local image is available.
    init(
        imageName: String? = nil,
        imageURL: URL? = nil
    ) {
        self.imageName = imageName
        self.imageURL = imageURL
    }

    var body: some View {
        Group {
            if let imageName, hasLocalImage {
                localImage(named: imageName)
            } else if let imageURL {
                remoteImage(from: imageURL)
            } else {
                placeholder
            }
        }
        .clipped()
        .background(Color.black.opacity(0.05))
        .accessibilityAddTraits(.isImage)
    }

    private var hasLocalImage: Bool {
        guard let imageName, !imageName.isEmpty else {
            return false
        }

        return UIImage(named: imageName) != nil
    }

    private func localImage(
        named name: String
    ) -> some View {
        Image(name)
            .resizable()
            .scaledToFill()
    }

    private func remoteImage(
        from url: URL
    ) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                loadingPlaceholder

            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()

            case .failure:
                placeholder

            @unknown default:
                placeholder
            }
        }
    }

    private var loadingPlaceholder: some View {
        ZStack {
            Color.gray.opacity(0.12)

            ProgressView()
                .progressViewStyle(.circular)
                .tint(.secondary)
        }
    }

    private var placeholder: some View {
        ZStack {
            Color.gray.opacity(0.12)

            Image(systemName: "person.crop.square")
                .font(.system(size: 36))
                .foregroundStyle(.secondary)
        }
    }
}
