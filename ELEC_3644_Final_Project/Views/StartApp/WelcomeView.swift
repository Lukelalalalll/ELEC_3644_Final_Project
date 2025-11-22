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
    @State private var isShowingContent = false // 控制内容显示的动画状态
    
    var body: some View {
        ZStack {
            // 渐变背景 - 也要参与动画
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .offset(y: isShowingContent ? 0 : UIScreen.main.bounds.height)
            .opacity(isShowingContent ? 1.0 : 0.0)
            
            VStack(spacing: 40) {
                Spacer()
                
                // 欢迎标题
                VStack(spacing: 16) {
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .scaleEffect(isShowingContent ? 1.0 : 0.8)
                        .opacity(isShowingContent ? 1.0 : 0.0)
                    
                    Text("Welcome to EduApp")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .opacity(isShowingContent ? 1.0 : 0.0)
                    
                    Text("Your learning journey starts here")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .opacity(isShowingContent ? 1.0 : 0.0)
                }
                
                Spacer()
                
                // 按钮区域
                VStack(spacing: 16) {
                    // 登录按钮
                    Button(action: {
                        withAnimation(.spring()) {
                            showLogin = true
                        }
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
                    .opacity(isShowingContent ? 1.0 : 0.0)
                    
                    // 注册按钮
                    Button(action: {
                        withAnimation(.spring()) {
                            showRegister = true
                        }
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
                    .opacity(isShowingContent ? 1.0 : 0.0)
                }
                .padding(.horizontal, 32)
                
                Spacer()
            }
            // 整个内容区域的偏移动画
            .offset(y: isShowingContent ? 0 : UIScreen.main.bounds.height * 0.3)
        }
        .onAppear {
            // 当视图出现时触发入场动画
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                isShowingContent = true
            }
        }
        .onDisappear {
            // 当视图消失时重置动画状态
            withAnimation(.easeOut(duration: 0.3)) {
                isShowingContent = false
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
