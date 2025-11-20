//
//  HomeView.swift
//  ELEC_3644_Final_Project
//
//  Created by cccakkke on 2025/11/20.
//


import SwiftUI

struct HomeView: View {
    var body: some View {
        Color(UIColor.systemBackground)
            .ignoresSafeArea()
            .overlay(
                VStack {
                    Text("Home")
                        .font(.system(size: 34, weight: .bold))
                    Text("欢迎来到首页")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            )
    }
}

#Preview {
    HomeView()
}
