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
                            Text("Enter your registered email")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            TextField("Enter your email", text: $username)
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
    
    // 在 LoginView.swift 中修改 login 函数
    private func login() {
        isLoading = true
        showError = false
        
        // 使用 Firebase 登录
        FirebaseService.shared.loginUser(email: username, password: password) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let user):
                    // 保存登录状态和用户信息
                    UserDefaults.standard.set(true, forKey: "isLoggedIn")
                    UserDefaults.standard.set(user.username, forKey: "currentUsername")
                    UserDefaults.standard.set(user.userId, forKey: "currentUserId")
                    
                    // 登录成功
                    self.dismiss()
                    self.showMainApp = true
                    
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
                
                self.isLoading = false
            }
        }
    }
}

#Preview {
    LoginView(showMainApp: .constant(false))
}
