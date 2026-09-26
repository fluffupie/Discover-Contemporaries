import Foundation

/// SERVICE (not one of the three MVVM letters)
///
/// Reading a file is not "data" and it is not "screen logic", so it lives on its
/// own. The ViewModel calls this; the View never does.
///
/// Keeping it separate means you can later swap the file for a real network call
/// and only ONE file changes.
enum JSONLoader {

    enum LoaderError: LocalizedError {
        case fileNotFound(String)
        case decodingFailed(String)

        var errorDescription: String? {
            switch self {
            case .fileNotFound(let name):
                return "Could not find \(name) in the app bundle. Did you add it to the target?"
            case .decodingFailed(let reason):
                return "The JSON did not match the model: \(reason)"
            }
        }
    }

    /// Loads and decodes a JSON file that ships inside the app bundle.
    ///
    /// - Parameters:
    ///   - filename: file name including extension, e.g. "books.json"
    ///   - subdirectory: pass "Data" ONLY if you added the folder to Xcode as a
    ///     *folder reference* (blue icon). If you added it as a *group*
    ///     (yellow icon, the default), leave this nil.
    static func load<T: Decodable>(
        _ filename: String,
        as type: T.Type,
        subdirectory: String? = nil
    ) throws -> T {

        guard let url = Bundle.main.url(
            forResource: filename,
            withExtension: nil,
            subdirectory: subdirectory
        ) else {
            throw LoaderError.fileNotFound(filename)
        }

        let data = try Data(contentsOf: url)

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw LoaderError.decodingFailed(error.localizedDescription)
        }
    }
}
