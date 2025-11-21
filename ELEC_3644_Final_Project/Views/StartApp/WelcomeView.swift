//
//  WelcomeView.swift
//  ELEC_3644_Final_Project
//
//  Created by cccakkke on 2025/11/21.
//
//
//  WelcomeView.swift
//  ELEC_3644_Final_Project
//
//  Created by cccakkke on 2025/11/21.
//

import SwiftUI

struct WelcomeView: View {
    @State private var showLogin = false
    @State private var showRegister = false
    @State private var showMainApp = false
    
    var body: some View {
        ZStack {
            // 渐变背景
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // 欢迎标题
                VStack(spacing: 16) {
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                    
                    Text("Welcome to EduApp")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Your learning journey starts here")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                // 按钮区域
                VStack(spacing: 16) {
                    // 登录按钮
                    Button(action: {
                        showLogin = true
                    }) {
                        Text("Login")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                    
                    // 注册按钮
                    Button(action: {
                        showRegister = true
                    }) {
                        Text("Register")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
        }
        .fullScreenCover(isPresented: $showLogin) {
            LoginView(showMainApp: $showMainApp)
        }
        .fullScreenCover(isPresented: $showRegister) {
            RegisterView(showMainApp: $showMainApp)
        }
        .fullScreenCover(isPresented: $showMainApp) {
            MainTabContainerView()
        }
    }
}

#Preview {
    WelcomeView()
}
