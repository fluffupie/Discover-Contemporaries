import FirebaseAuth
import FirebaseFirestore
import Foundation
import OSLog

// MARK: - Service Protocol

/// Bookmark operations for saving, removing, checking and retrieving figures.
protocol BookmarkServiceProtocol: Sendable {
    func save(_ figure: HistoricalFigure) async throws
    func remove(_ figureID: String) async throws
    func isSaved(_ figureID: String) async throws -> Bool
    func fetchAll() async throws -> [BookmarkedFigure]
}

// MARK: - Firestore Implementation

/// Stores bookmarks in Firestore under `users/{uid}/bookmarks/{figureID}`.
///
/// - Important: Every operation throws ``BookmarkError/notSignedIn`` if no
///   Firebase user exists yet. Anonymous sign-in is asynchronous, so calls
///   made right at launch can hit this.
final class BookmarkService: BookmarkServiceProtocol {
    static let shared: BookmarkServiceProtocol = BookmarkService()

    private let db: Firestore
    private let auth: Auth
    private let logger = Logger(subsystem: "a2.DiscoverContemporaries", category: "Bookmarks")

    /// Creates a service.
    /// - Parameters:
    ///   - db: The Firestore instance. Defaults to the shared one.
    ///   - auth: The Auth instance. Defaults to the shared one.
    init(db: Firestore = .firestore(), auth: Auth = .auth()) {
        self.db = db
        self.auth = auth
    }

    func save(_ figure: HistoricalFigure) async throws {
        let ref = try bookmarkDocument(figureID: figure.id)
        try await ref.setData(from: BookmarkedFigure(from: figure))
    }

    func remove(_ figureID: String) async throws {
        try await bookmarkDocument(figureID: figureID).delete()
    }

    func isSaved(_ figureID: String) async throws -> Bool {
        try await bookmarkDocument(figureID: figureID).getDocument().exists
    }

    func fetchAll() async throws -> [BookmarkedFigure] {
        let snapshot = try await bookmarksCollection()
            .order(by: "savedAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { document in
            do {
                return try document.data(as: BookmarkedFigure.self)
            } catch {
                logger.error(
                    "Skipping bookmark \(document.documentID): \(error.localizedDescription)"
                )
                return nil
            }
        }

    }

    // MARK: - Helpers

    private func currentUserID() throws -> String {
        guard let userID = auth.currentUser?.uid else {
            throw BookmarkError.notSignedIn
        }
        return userID
    }

    private func bookmarksCollection() throws -> CollectionReference {
        db.collection("users")
            .document(try currentUserID())
            .collection("bookmarks")
    }

    private func bookmarkDocument(figureID: String) throws -> DocumentReference
    {
        try bookmarksCollection().document(figureID)
    }
}

// MARK: - Bookmark Error

/// Errors that can occur while accessing bookmarks.
enum BookmarkError: LocalizedError {
    /// There is no signed-in Firebase user.
    case notSignedIn

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            String(localized: "User is not signed in.")
        }
    }
}
