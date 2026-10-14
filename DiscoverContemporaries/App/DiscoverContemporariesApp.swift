import FirebaseAuth
import FirebaseCore
import SwiftData
import SwiftUI

/// The application delegate responsible for Firebase setup at launch.
///
/// `AppDelegate` configures Firebase and makes sure the user has an
/// authenticated identity by signing in anonymously when no user session
/// exists.
final class AppDelegate: NSObject, UIApplicationDelegate {
    /// Configures Firebase and starts anonymous authentication if needed.
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions:
            [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        signInAnonymouslyIfNeeded()

        return true
    }

    /// Signs the user in anonymously if there is no current Firebase user.
    ///
    /// If a user session already exists (for example, restored from a previous
    /// launch), this method returns immediately without making a network
    /// request. Results are reported through `print`.
    private func signInAnonymouslyIfNeeded() {
        guard Auth.auth().currentUser == nil else {
            return
        }

        Auth.auth().signInAnonymously { authResult, error in
            if let error {
                print("Anonymous sign-in failed: \(error)")
                return
            }

            if let user = authResult?.user {
                print("Signed in anonymously as: \(user.uid)")
            }
        }
    }
}

@main
struct DiscoverContemporariesApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self)
    private var delegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: CachedHistoricalFigure.self)
    }
}
