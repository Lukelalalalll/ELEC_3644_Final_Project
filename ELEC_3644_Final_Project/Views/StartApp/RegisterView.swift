//
//  RegisterView.swift
//  ELEC_3644_Final_Project
//
//  Created by cccakkke on 2025/11/21.
//

import SwiftUI
import SwiftData

struct RegisterView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Binding var showMainApp: Bool
    
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var email = ""
    @State private var selectedGender = "Male"
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    
    let genders = ["Male", "Female", "Other"]
    
    init(showMainApp: Binding<Bool>) {
        self._showMainApp = showMainApp
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        
                        VStack(spacing: 10) {
                            Text("Create Account")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Text("Join our learning community")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 30)
                        
                      
                        VStack(spacing: 20) {
                          
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Username")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                TextField("Choose a username", text: $username)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                            }
                            
                           
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                TextField("Enter your email", text: $email)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .autocorrectionDisabled()
                            }
                            
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Gender")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Picker("Gender", selection: $selectedGender) {
                                    ForEach(genders, id: \.self) { gender in
                                        Text(gender)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                            }
                            
                            // 密码
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                SecureField("Create a password", text: $password)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .textContentType(.none)
                                    .autocapitalization(.none)
                            }
                            
                          
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                SecureField("Confirm your password", text: $confirmPassword)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .textContentType(.none)  
                                    .autocapitalization(.none)
                            }
                        }
                        .padding(.horizontal, 32)
                        
                        
                        if showError {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        
                        Spacer()
                        
                     
                        Button(action: register) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Create Account")
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
                        .disabled(isLoading || !isFormValid)
                        .opacity((isLoading || !isFormValid) ? 0.6 : 1.0)
                        
                        // 返回欢迎页面按钮
                        Button("Back to Welcome") {
                            dismiss()
                        }
                        .foregroundColor(.blue)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private var isFormValid: Bool {
        !username.isEmpty &&
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        password == confirmPassword &&
        password.count >= 6
    }
    
    private func register() {
        guard !username.isEmpty else {
            errorMessage = "Please enter a username"
            showError = true
            return
        }
        
        guard !email.isEmpty else {
            errorMessage = "Please enter an email"
            showError = true
            return
        }
        
        guard password.count >= 6 else {
            errorMessage = "Password must be at least 6 characters"
            showError = true
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match"
            showError = true
            return
        }
        
        isLoading = true
        showError = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let usernamePredicate = #Predicate<User> { user in
                user.username == username
            }
            
            let emailPredicate = #Predicate<User> { user in
                user.email == email
            }
            
            do {
                let existingUsers = try modelContext.fetch(FetchDescriptor<User>(predicate: usernamePredicate))
                let existingEmails = try modelContext.fetch(FetchDescriptor<User>(predicate: emailPredicate))
                
                if !existingUsers.isEmpty {
                    errorMessage = "Username already exists"
                    showError = true
                } else if !existingEmails.isEmpty {
                    errorMessage = "Email already registered"
                    showError = true
                } else {
                    let newUser = User(
                        userId: UUID().uuidString,
                        username: username,
                        password: password,
                        email: email,
                        gender: selectedGender
                    )
                    
                    modelContext.insert(newUser)
                    
                    do {
                        try modelContext.save()
                        // 保存登录状态和用户名
                        UserDefaults.standard.set(true, forKey: "isLoggedIn")
                        UserDefaults.standard.set(username, forKey: "currentUsername")
                        
                        // 注册成功，关闭当前页面并显示主应用
                        dismiss()
                        showMainApp = true
                    } catch {
                        errorMessage = "Registration failed. Please try again."
                        showError = true
                    }
                }
            } catch {
                errorMessage = "Registration failed. Please try again."
                showError = true
            }
            
            isLoading = false
        }
    }
}

#Preview {
    RegisterView(showMainApp: .constant(false))
}
