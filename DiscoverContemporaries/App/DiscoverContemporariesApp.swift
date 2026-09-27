import CoreText
import FirebaseCore
import SwiftData
import SwiftUI
import FirebaseFirestore

// Firebase setup
// If you're using SwiftUI, you must create an application delegate and attach it to your App struct via UIApplicationDelegateAdaptor
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication
            .LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Use Firebase library to configure APIs
        FirebaseApp.configure() // Configure a FirebaseApp shared instance

        let db = Firestore.firestore()
        db.collection("test").addDocument(data: [
            "message": "Firebase connected"
        ]) { error in
            if let error {
                print("Firebase error:", error)
            } else {
                print("Firebase connected successfully")
            }
        }

        return true
    }
}

// app entry point
@main
struct DiscoverContemporariesApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    init() {
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // SwiftData models
        .modelContainer(for: [CachedHistoricalFigure.self])
    }
}
