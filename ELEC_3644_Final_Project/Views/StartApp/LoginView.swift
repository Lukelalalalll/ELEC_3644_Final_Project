//
//  LoginView.swift
//  ELEC_3644_Final_Project
//
//  Created by cccakkke on 2025/11/21.
//

//
//  LoginView.swift
//  ELEC_3644_Final_Project
//
//  Created by cccakkke on 2025/11/21.
//

import SwiftUI
import SwiftData

struct LoginView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Binding var showMainApp: Bool
    
    @State private var username = ""
    @State private var password = ""
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    init(showMainApp: Binding<Bool>) {
        self._showMainApp = showMainApp
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // 背景
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // 头部
                    VStack(spacing: 10) {
                        Text("Login")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Welcome back!")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 50)
                    
                    // 表单
                    VStack(spacing: 20) {
                        // 用户名输入
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Username")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Enter your username", text: $username)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }
                        
                        // 密码输入
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            SecureField("Enter your password", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    // 错误提示
                    if showError {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    
                    Spacer()
                    
                    // 登录按钮
                    Button(action: login) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Login")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                    .padding(.horizontal, 32)
                    .disabled(isLoading || username.isEmpty || password.isEmpty)
                    .opacity((isLoading || username.isEmpty || password.isEmpty) ? 0.6 : 1.0)
                    
                    // 返回欢迎页面按钮
                    Button("Back to Welcome") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func login() {
        isLoading = true
        showError = false
        
        // 模拟网络请求延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // 验证用户
            let predicate = #Predicate<User> { user in
                user.username == username && user.password == password
            }
            
            let descriptor = FetchDescriptor<User>(predicate: predicate)
            
            // 在登录成功的 else 分支中添加：
            do {
                let users = try modelContext.fetch(descriptor)
                
                if users.isEmpty {
                    errorMessage = "Invalid username or password"
                    showError = true
                } else {
                    // 保存登录状态和用户名
                    UserDefaults.standard.set(true, forKey: "isLoggedIn")
                    UserDefaults.standard.set(username, forKey: "currentUsername")
                    
                    // 登录成功，关闭当前页面并显示主应用
                    dismiss()
                    showMainApp = true
                }
            } catch {
                errorMessage = "Login failed. Please try again."
                showError = true
            }
            
            isLoading = false
        }
    }
}

#Preview {
    LoginView(showMainApp: .constant(false))
}
