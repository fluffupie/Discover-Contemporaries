import FirebaseAuth
import FirebaseFirestore
import Foundation

// MARK: - Service Protocol
/// Defines bookmark operations for saving, removing, checking, and retrieving historical figures.
protocol BookmarkServiceProtocol {
    func save(_ figure: HistoricalFigure) async throws
    func remove(_ figureID: String) async throws
    func isSaved(_ figureID: String) async throws -> Bool
    func fetchAll() async throws -> [BookmarkedFigure]
}

// MARK: - Bookmark Service
/// Provides bookmark operations through the configured Firebase adapter.
final class BookmarkService: BookmarkServiceProtocol {
    static let shared: BookmarkServiceProtocol = BookmarkService()

    private init() {}

    func save(_ figure: HistoricalFigure) async throws {
        try await FirebaseBookmarkAdapter.shared.save(figure)
    }

    func remove(_ figureID: String) async throws {
        try await FirebaseBookmarkAdapter.shared.remove(figureID)
    }

    func isSaved(_ figureID: String) async throws -> Bool {
        try await FirebaseBookmarkAdapter.shared.isSaved(figureID)
    }

    func fetchAll() async throws -> [BookmarkedFigure] {
        try await FirebaseBookmarkAdapter.shared.fetchAll()
    }
}

// MARK: - Firebase Adapter
/// Handles bookmark persistence in Firebase Firestore for the current authenticated user.
final class FirebaseBookmarkAdapter {
    static let shared = FirebaseBookmarkAdapter()

    private let db = Firestore.firestore()

    private init() {}

    /// Saves a historical figure as a bookmark for the current user.
    func save(_ figure: HistoricalFigure) async throws {
        let userID = try currentUserID()
        let bookmarked = BookmarkedFigure(from: figure)

        var data: [String: Any] = [
            "id": bookmarked.id,
            "name": bookmarked.name,
            "savedAt": FieldValue.serverTimestamp()
        ]

        if let descriptionText = bookmarked.descriptionText {
            data["descriptionText"] = descriptionText
        }

        if let birthDate = bookmarked.birthDate {
            data["birthDate"] = Timestamp(date: birthDate)
        }

        if let deathDate = bookmarked.deathDate {
            data["deathDate"] = Timestamp(date: deathDate)
        }

        if let imageURL = bookmarked.imageURL {
            data["imageURL"] = imageURL.absoluteString
        }

        if let imageName = bookmarked.imageName {
            data["imageName"] = imageName
        }

        try await bookmarkDocument(
            userID: userID,
            figureID: bookmarked.id
        )
        .setData(data)
    }

    /// Removes the bookmark for the specified historical figure.
    func remove(_ figureID: String) async throws {
        let userID = try currentUserID()

        try await bookmarkDocument(
            userID: userID,
            figureID: figureID
        )
        .delete()
    }

    /// Returns whether the specified historical figure is bookmarked.
    func isSaved(_ figureID: String) async throws -> Bool {
        let userID = try currentUserID()

        let snapshot = try await bookmarkDocument(
            userID: userID,
            figureID: figureID
        )
        .getDocument()

        return snapshot.exists
    }

    /// Returns all bookmarks for the current user.
    func fetchAll() async throws -> [BookmarkedFigure] {
        let userID = try currentUserID()

        let snapshot = try await db
            .collection("users")
            .document(userID)
            .collection("bookmarks")
            .order(by: "savedAt", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { document in
            let data = document.data()

            return BookmarkedFigure(
                id: data["id"] as? String
                    ?? document.documentID,
                name: data["name"] as? String
                    ?? "Unknown",
                descriptionText: data["descriptionText"] as? String,
                birthDate: (data["birthDate"] as? Timestamp)?
                    .dateValue(),
                deathDate: (data["deathDate"] as? Timestamp)?
                    .dateValue(),
                imageURL: (data["imageURL"] as? String)
                    .flatMap(URL.init(string:)),
                imageName: data["imageName"] as? String
            )
        }
    }

    // MARK: - Helpers

    private func currentUserID() throws -> String {
        guard let userID = Auth.auth().currentUser?.uid else {
            throw BookmarkError.notSignedIn
        }

        return userID
    }

    private func bookmarkDocument(
        userID: String,
        figureID: String
    ) -> DocumentReference {
        db
            .collection("users")
            .document(userID)
            .collection("bookmarks")
            .document(figureID)
    }
}

// MARK: - Bookmark Error
/// Represents errors that can occur while accessing bookmarks.
enum BookmarkError: LocalizedError {
    case notSignedIn

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "User is not signed in."
        }
    }
}
