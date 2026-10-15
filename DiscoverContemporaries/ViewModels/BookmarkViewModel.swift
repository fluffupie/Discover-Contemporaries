import Combine
import Foundation
import OSLog

/// Manages loading, removal and error state for bookmarked figures.
@MainActor
final class BookmarkViewModel: ObservableObject {
    /// The saved figures, most recently saved first.
    @Published private(set) var figures: [BookmarkedFigure] = []

    /// `true` only while loading with nothing on screen yet.
    ///
    /// Refreshes of an existing list leave this `false`, so use
    /// `.refreshable` for its own indicator.
    @Published private(set) var isLoading = false

    /// A user-facing error message, or `nil`.
    @Published private(set) var errorMessage: String?

    private let bookmarkService: BookmarkServiceProtocol
    private var isLoadInFlight = false
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "DiscoverContemporaries",
        category: "Bookmarks"
    )

    /// Creates a view model.
    /// - Parameter bookmarkService: The service to use. Defaults to the shared one.
    init(bookmarkService: BookmarkServiceProtocol = BookmarkService.shared) {
        self.bookmarkService = bookmarkService
    }

    // MARK: - Loading

    /// Loads all bookmarks.
    ///
    /// On failure the current list is kept, so a failed refresh doesn't blank
    /// the screen. Calls made while a load is running are ignored.
    func load() async {
        guard !isLoadInFlight else { return }
        isLoadInFlight = true
        isLoading = figures.isEmpty
        errorMessage = nil

        defer {
            isLoadInFlight = false
            isLoading = false
        }

        do {
            figures = try await bookmarkService.fetchAll()
        } catch is CancellationError {
            // The view went away. Not an error.
        } catch BookmarkError.notSignedIn {
            errorMessage = String(localized: "Still signing you in. Pull to refresh in a moment.")
        } catch {
            errorMessage = String(localized: "Unable to load saved figures.")
            logger.error("Failed to load bookmarks: \(error.localizedDescription)")
        }
    }

    /// Reloads the bookmarks.
    func refresh() async {
        await load()
    }

    // MARK: - Remove

    /// Removes a bookmark, updating the list immediately.
    ///
    /// If the delete fails, the figure is restored at its original position.
    ///
    /// - Parameter figure: The bookmark to remove.
    func remove(_ figure: BookmarkedFigure) async {
        errorMessage = nil

        guard let index = figures.firstIndex(where: { $0.id == figure.id }) else {
            return
        }
        let removed = figures.remove(at: index)

        do {
            try await bookmarkService.remove(figure.id)
        } catch {
            let restoreIndex = min(index, figures.count)
            figures.insert(removed, at: restoreIndex)
            errorMessage = String(localized: "Unable to remove saved figure.")
            logger.error("Failed to remove bookmark \(figure.id): \(error.localizedDescription)")
        }
    }

    // MARK: - Error State

    /// Clears the current error message.
    func clearError() {
        errorMessage = nil
    }
}
