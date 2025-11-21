//
//  ProfileView.swift
//  ELEC_3644_Final_Project
//
//  Created by cccakkke on 2025/11/20.
//
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
    @AppStorage("currentUserId") private var currentUserId = "" // 确保有这个
    
    @State private var currentUser: User?
    @State private var showLogoutAlert = false
    @State private var isLoading = true
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if isLoading {
                    // 加载状态
                    ProgressView("Loading profile...")
                } else if let user = currentUser {
                    // 用户数据加载成功
                    userProfileView(user: user)
                } else {
                    // 加载失败或未找到用户
                    VStack(spacing: 20) {
                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        
                        Text("User Not Found")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Unable to load user profile")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        Button("Retry") {
                            loadCurrentUser()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
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
    
    private func userProfileView(user: User) -> some View {
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
                    InfoRow(icon: "number", title: "User ID", value: String(user.userId.prefix(8)) + "...")
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // 统计信息卡片（可选）
                VStack(alignment: .leading, spacing: 16) {
                    Text("Statistics")
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    InfoRow(icon: "note.text", title: "Posts", value: "\(user.posts.count)")
                    InfoRow(icon: "book.fill", title: "Courses", value: "\(user.courses.count)")
                    InfoRow(icon: "message.fill", title: "Comments", value: "\(user.postComments.count + user.courseComments.count)")
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
    }
    
    private func loadCurrentUser() {
        guard !currentUserId.isEmpty else {
            // 如果没有 currentUserId，尝试使用 currentUsername 从 Firebase 查询
            if !currentUsername.isEmpty {
                loadUserByUsername()
            } else {
                isLoading = false
                errorMessage = "No user information found"
            }
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        // 从 Firebase 获取用户数据
        FirebaseService.shared.getCurrentUser { user in
            DispatchQueue.main.async {
                if let user = user {
                    self.currentUser = user
                    
                    // 可选：同时保存到本地 SwiftData 用于离线访问
                    self.saveUserToLocalStorage(user: user)
                } else {
                    self.errorMessage = "Failed to load user data from server"
                }
                self.isLoading = false
            }
        }
    }
    
    private func saveUserToLocalStorage(user: User) {
        do {
            // 使用更简单的查询方式
            let descriptor = FetchDescriptor<User>()
            let allUsers = try modelContext.fetch(descriptor)
            
            // 手动查找匹配的用户
            if let existingUser = allUsers.first(where: { $0.userId == user.userId }) {
                // 更新现有用户数据
                existingUser.username = user.username
                existingUser.email = user.email
                existingUser.gender = user.gender
            } else {
                // 插入新用户
                modelContext.insert(user)
            }
            try modelContext.save()
        } catch {
            print("Error saving user to local storage: \(error)")
        }
    }
    
    private func loadUserByUsername() {
        // 这个方法需要先在 FirebaseService 中添加通过用户名查询用户的功能
        // 暂时先设置为加载失败
        isLoading = false
        errorMessage = "Please log in again"
    }
    
    private func logout() {
        // 调用 Firebase 登出
        FirebaseService.shared.logout()
        
        // 清除登录状态
        isLoggedIn = false
        currentUsername = ""
        currentUserId = ""
        currentUser = nil
        
        // 可选：清除本地用户数据
        // clearLocalUserData()
    }
    
    private func clearLocalUserData() {
        // 清除本地 SwiftData 中的用户数据（可选）
        do {
            let descriptor = FetchDescriptor<User>()
            let users = try modelContext.fetch(descriptor)
            for user in users {
                modelContext.delete(user)
            }
            try modelContext.save()
        } catch {
            print("Error clearing local user data: \(error)")
        }
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
