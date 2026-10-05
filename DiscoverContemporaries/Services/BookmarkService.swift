import FirebaseAuth
import FirebaseFirestore
import Foundation

// MARK: - Bookmark Model

struct SavedFigure: Codable, Identifiable {
    let id: String
    let name: String
    let descriptionText: String?
    let birthDate: Date?
    let deathDate: Date?
    let imageURL: URL?
    let imageName: String?

    init(from figure: HistoricalFigure) {
        self.id = figure.id
        self.name = figure.name
        self.descriptionText = figure.descriptionText
        self.birthDate = figure.birthDate
        self.deathDate = figure.deathDate
        self.imageURL = figure.imageURL
        self.imageName = figure.imageName
    }
}

// MARK: - Service Protocol

protocol BookmarkServiceProtocol {
    func save(_ figure: HistoricalFigure) async throws
    func remove(_ figureID: String) async throws
    func isSaved(_ figureID: String) async throws -> Bool
}

// MARK: - Bookmark Service

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
}

// MARK: - Firebase Adapter

final class FirebaseBookmarkAdapter {
    static let shared = FirebaseBookmarkAdapter()

    private let db = Firestore.firestore()

    private init() {}

    func save(_ figure: HistoricalFigure) async throws {
        let userID = try currentUserID()
        let saved = SavedFigure(from: figure)

        try await bookmarkDocument(
            userID: userID,
            figureID: saved.id
        )
        .setData([
            "id": saved.id,
            "name": saved.name,
            "descriptionText": saved.descriptionText as Any,
            "birthDate": saved.birthDate as Any,
            "deathDate": saved.deathDate as Any,
            "imageURL": saved.imageURL?.absoluteString as Any,
            "imageName": saved.imageName as Any,
            "savedAt": FieldValue.serverTimestamp()
        ])
    }

    func remove(_ figureID: String) async throws {
        let userID = try currentUserID()

        try await bookmarkDocument(
            userID: userID,
            figureID: figureID
        )
        .delete()
    }

    func isSaved(_ figureID: String) async throws -> Bool {
        let userID = try currentUserID()

        let snapshot = try await bookmarkDocument(
            userID: userID,
            figureID: figureID
        )
        .getDocument()

        return snapshot.exists
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

enum BookmarkError: LocalizedError {
    case notSignedIn

    var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "User is not signed in."
        }
    }
}
