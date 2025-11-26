import SwiftUI
import SwiftData
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct ELEC_3644_Final_ProjectApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    
    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                MainTabContainerView()
                    .onAppear {
                        UserDefaults.standard.set(true, forKey: "forceRefreshPosts")
                    }
            } else {
                WelcomeView()
            }
        }
        .modelContainer(for: [
            User.self,
            Post.self,
            PostComment.self,
            Course.self,
            CourseComment.self
        ])
    }
}
