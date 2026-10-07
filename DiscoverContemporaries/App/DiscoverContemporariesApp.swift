import FirebaseAuth
import FirebaseCore
import SwiftData
import SwiftUI

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions:
            [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        signInAnonymouslyIfNeeded()

        return true
    }

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
