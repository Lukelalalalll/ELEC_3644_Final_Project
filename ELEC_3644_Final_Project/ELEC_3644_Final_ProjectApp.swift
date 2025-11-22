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
                    .onAppear {
                        // 应用启动时的全局数据刷新
                        print("应用启动，准备刷新数据...")
                        // 设置强制刷新标志，确保用户登录后能看到最新数据
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
