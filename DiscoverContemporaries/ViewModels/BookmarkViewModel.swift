import Combine
import Foundation

@MainActor
final class BookmarkViewModel: ObservableObject {

    @Published private(set) var figures: [BookmarkedFigure] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let bookmarkService: BookmarkServiceProtocol

    init(
        bookmarkService: BookmarkServiceProtocol = BookmarkService.shared
    ) {
        self.bookmarkService = bookmarkService
    }

    // MARK: - Loading

    func load() async {
        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            figures = try await bookmarkService.fetchAll()
        } catch {
            figures = []
            errorMessage = "Unable to load saved figures."
            print("Failed to load bookmarks: \(error)")
        }
    }

    // MARK: - Remove

    func remove(_ figure: BookmarkedFigure) async {
        errorMessage = nil

        do {
            try await bookmarkService.remove(figure.id)

            figures.removeAll {
                $0.id == figure.id
            }
        } catch {
            errorMessage = "Unable to remove saved figure."
            print(
                "Failed to remove bookmark \(figure.id): \(error)"
            )
        }
    }

    // MARK: - Refresh

    func refresh() async {
        await load()
    }

    // MARK: - Error State

    func clearError() {
        errorMessage = nil
    }
}
