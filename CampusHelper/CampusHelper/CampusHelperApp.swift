import SwiftUI
import SwiftData

@main
struct CampusHelperApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            Course.self,
            Post.self,
            PostComment.self,
            ClassTime.self,
            Homework.self,
            CourseComment.self,
            Item.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
