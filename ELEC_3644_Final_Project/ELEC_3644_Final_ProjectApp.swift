//
//  ELEC_3644_Final_ProjectApp.swift
//  ELEC_3644_Final_Project
//
//  Created by cccakkke on 2025/11/18.
//

import SwiftUI
import SwiftData

@main
struct ELEC_3644_Final_ProjectApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabContainerView()
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
