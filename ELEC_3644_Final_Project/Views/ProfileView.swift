//
//  ProfileView.swift
//  ELEC_3644_Final_Project
//
//  Created by cccakkke on 2025/11/20.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        Color(UIColor.systemBackground)
            .ignoresSafeArea()
            .overlay(
                Text("Profile")
                    .font(.system(size: 34, weight: .bold))
            )
    }
}

#Preview {
    ProfileView()
}
