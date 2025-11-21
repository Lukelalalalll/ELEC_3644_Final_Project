//
//  ProfileView.swift
//  ELEC_3644_Final_Project
//
//  Created by cccakkke on 2025/11/20.
//


import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("currentUsername") private var currentUsername = ""
    
    @State private var currentUser: User?
    @State private var showLogoutAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if let user = currentUser {
                    ScrollView {
                        VStack(spacing: 24) {
                            // 用户头像和信息区域
                            VStack(spacing: 16) {
                                // 头像
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.2))
                                        .frame(width: 100, height: 100)
                                    
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 80))
                                        .foregroundColor(.blue)
                                }
                                .padding(.top, 20)
                                
                                // 用户名
                                Text(user.username)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                // 邮箱
                                Text(user.email)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                
                                // 加入天数
                                HStack {
                                    Image(systemName: "calendar")
                                    Text("Joined \(user.daysSinceJoin()) days ago")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                            
                            // 个人信息卡片
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Personal Information")
                                    .font(.headline)
                                    .padding(.bottom, 8)
                                
                                InfoRow(icon: "person.fill", title: "Username", value: user.username)
                                InfoRow(icon: "envelope.fill", title: "Email", value: user.email)
                                InfoRow(icon: "person.2.fill", title: "Gender", value: user.gender)
                                InfoRow(icon: "number", title: "User ID", value: user.userId.prefix(8) + "...")
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                            
                            // 登出按钮
                            Button(action: {
                                showLogoutAlert = true
                            }) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Log Out")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            .padding(.top, 20)
                            
                            Spacer()
                        }
                        .padding(.vertical)
                    }
                } else {
                    // 加载状态或未找到用户
                    ProgressView("Loading profile...")
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .alert("Log Out", isPresented: $showLogoutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Log Out", role: .destructive) {
                    logout()
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
        }
        .onAppear {
            loadCurrentUser()
        }
    }
    
    private func loadCurrentUser() {
        guard !currentUsername.isEmpty else { return }
        
        let predicate = #Predicate<User> { user in
            user.username == currentUsername
        }
        
        let descriptor = FetchDescriptor<User>(predicate: predicate)
        
        do {
            let users = try modelContext.fetch(descriptor)
            currentUser = users.first
        } catch {
            print("Error loading current user: \(error)")
        }
    }
    
    private func logout() {
        // 清除登录状态
        isLoggedIn = false
        currentUsername = ""
        
        // 这里可以添加其他清理操作，比如清除缓存等
    }
}

// 信息行组件
struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [User.self])
}
