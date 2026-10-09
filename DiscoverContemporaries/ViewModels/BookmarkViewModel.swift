import Combine
import Foundation

/// Manages the loading, removal, and error state of bookmarked historical figures.
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

    /// Loads all bookmarked historical figures from the bookmark service.
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

    /// Removes the specified bookmarked figure from storage and the local list.
    ///
    /// - Parameter figure: The bookmarked figure to remove.
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

    /// Reloads the current list of bookmarked historical figures.
    func refresh() async {
        await load()
    }

    // MARK: - Error State

    /// Clears the current bookmark error message.
    func clearError() {
        errorMessage = nil
    }
}
