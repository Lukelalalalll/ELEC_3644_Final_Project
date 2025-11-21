//
//  ELEC_3644_Final_ProjectApp.swift
//  ELEC_3644_Final_Project
//
//  Created by cccakkke on 2025/11/18.
//
//
//  ELEC_3644_Final_ProjectApp.swift
//  ELEC_3644_Final_Project
//
//  Created by cccakkke on 2025/11/18.
//

//
//  ELEC_3644_Final_ProjectApp.swift
//  ELEC_3644_Final_Project
//
//  Created by cccakkke on 2025/11/18.
//

import SwiftUI
import SwiftData
import FirebaseCore // 添加这行

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure() // 配置 Firebase
        return true
    }
}

@main
struct ELEC_3644_Final_ProjectApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate // 添加这行
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    
    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                MainTabContainerView()
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
