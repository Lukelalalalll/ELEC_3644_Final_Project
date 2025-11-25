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
                Color(.systemBackground).ignoresSafeArea()
                
                VStack(spacing: 30) {

                    VStack(spacing: 10) {
                        Text("Login")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Welcome back!")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 50)
                    
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Enter your registered email")
                                .font(.headline)
                            TextField("Enter your email", text: $username)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .keyboardType(.emailAddress)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.headline)
                            SecureField("Enter your password", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
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
        
        FirebaseService.shared.loginUser(email: username, password: password) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let firebaseUser):
                    FirebaseService.shared.getUserDataAndSyncCourses(
                        userId: firebaseUser.userId,
                        modelContext: self.modelContext    // 传 modelContext！
                    ) { syncResult in
                        DispatchQueue.main.async {
                            switch syncResult {
                            case .success(let fullUser):
                                // 登录成功 + 课程已同步到本地 SwiftData
                                UserDefaults.standard.set(true, forKey: "isLoggedIn")
                                UserDefaults.standard.set(fullUser.userId, forKey: "currentUserId")
                                UserDefaults.standard.set(fullUser.username, forKey: "currentUsername")
                                
                                print("Login success，已同步 \(fullUser.enrolledCourseIds.count) 门课程")
                                
                                self.dismiss()
                                self.showMainApp = true
                                
                            case .failure(let error):
                                self.errorMessage = "Failed to complete the synchronous course：\(error.localizedDescription)"
                                self.showError = true
                            }
                        }
                    }
                    
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
        }
    }
}

#Preview {
    LoginView(showMainApp: .constant(false))
}
