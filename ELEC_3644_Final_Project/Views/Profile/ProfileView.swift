import SwiftUI
import SwiftData
import PhotosUI
import FirebaseAuth


struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("currentUsername") private var currentUsername = ""
    @AppStorage("currentUserId") private var currentUserId = ""
    
    @State private var currentUser: User?
    @State private var showLogoutAlert = false
    @State private var isLoading = true
    @State private var errorMessage = ""
    @State private var userStats: UserStats?
    
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var isUploadingAvatar = false
    @State private var showImagePicker = false
    @State private var avatarImage: UIImage?
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemGroupedBackground),
                        Color(.systemGroupedBackground).opacity(0.8)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(.blue)
                        
                        Text("Loading Profile")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("Fetching your data...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(30)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    )
                } else if let user = currentUser {
                    userProfileView(user: user)
                } else {
                    errorStateView
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
            .photosPicker(isPresented: $showImagePicker, selection: $selectedItem, matching: .images)
            .onChange(of: selectedItem) { newItem in
                Task {
                    await loadImage(from: newItem)
                }
            }
        }
        .onAppear {
            loadCurrentUser()
        }
    }
    
    private func loadImage(from item: PhotosPickerItem?) async {
        guard let item = item,
              let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        
        await MainActor.run {
            self.avatarImage = image
            self.uploadAvatar(image: image)
        }
    }
    
    private func uploadAvatar(image: UIImage) {
        guard let user = currentUser,
              let imageData = image.jpegData(compressionQuality: 0.7) else {
            errorMessage = "Failed to prepare image for upload"
            return
        }
        
        isUploadingAvatar = true
        
        FirebaseService.shared.uploadUserAvatarToStorage(userId: user.userId, imageData: imageData) { result in
            DispatchQueue.main.async {
                self.isUploadingAvatar = false
                
                switch result {
                case .success(let downloadURL):
                    user.updateAvatar(imageData)
                    self.avatarImage = image
                    
                    self.saveUserToLocalStorage(user: user)
                    
                    self.errorMessage = "Avatar updated successfully!"
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.verifyAvatarStorage(user: user)
                    }
                    
                case .failure(let error):
                    user.updateAvatar(imageData)
                    self.avatarImage = image
                    self.saveUserToLocalStorage(user: user)
                }
            }
        }
    }

    private func verifyAvatarStorage(user: User) {
        FirebaseService.shared.getUserAvatarURL(userId: user.userId) { avatarURL in
        }
    }

    private func loadCurrentUser() {
        guard !currentUserId.isEmpty else {
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
        
        if Auth.auth().currentUser == nil {
            logout()
            return
        }
        
        FirebaseService.shared.getCurrentUser { user in
            DispatchQueue.main.async {
                if let user = user {
                    self.currentUser = user
                    
                    self.loadUserStats()
                    
                    self.loadUserAvatar(user: user)
                    
                } else {
                    self.errorMessage = "Failed to load user data from server"
                    self.isLoading = false
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        if self.currentUser == nil {
                            self.logout()
                        }
                    }
                }
            }
        }
    }

    private func loadUserAvatar(user: User) {
        FirebaseService.shared.downloadUserAvatarFromStorage(userId: user.userId) { avatarData in
            DispatchQueue.main.async {
                if let avatarData = avatarData, let image = UIImage(data: avatarData) {
                    user.updateAvatar(avatarData)
                    self.avatarImage = image
                    self.saveUserToLocalStorage(user: user)
                } else {
                    user.updateAvatar(nil)
                    self.avatarImage = nil
                    self.saveUserToLocalStorage(user: user)
                }
                self.isLoading = false
            }
        }
    }
    
    private var errorStateView: some View {
        VStack(spacing: 25) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 70))
                .foregroundColor(.orange)
                .symbolRenderingMode(.hierarchical)
            
            VStack(spacing: 8) {
                Text("User Not Found")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Unable to load user profile")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
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
            .buttonStyle(GradientButtonStyle())
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 20)
    }
    
    private func userProfileView(user: User) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                headerCard(user: user)
                
                myCoursesButton
                
                logoutButton
                
                personalInfoCard(user: user)
                
                statsCard()
                
                Spacer()
                    .frame(height: 40)
            }
            .padding(.vertical)
        }
        .onAppear {
            if currentUser != nil && userStats == nil {
                loadUserStats()
            }
        }
    }
    
    private func headerCard(user: User) -> some View {
        VStack(spacing: 20) {
            Button(action: {
                showImagePicker = true
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    if isUploadingAvatar {
                        ProgressView()
                            .scaleEffect(1.2)
                            .tint(.white)
                    } else if let avatarImage = avatarImage {
                        Image(uiImage: avatarImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 110, height: 110)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                            )
                    } else if let avatarData = user.avatar, let uiImage = UIImage(data: avatarData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 110, height: 110)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                            )
                    } else {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 100))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
                    }

                    Circle()
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                        )
                        .offset(x: 40, y: 40)
                }
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(isUploadingAvatar)
            
            VStack(spacing: 8) {
                Text(user.username)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(user.email)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding(25)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
    }
    
    private func personalInfoCard(user: User) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "person.text.rectangle.fill")
                    .foregroundColor(.blue)
                    .font(.headline)
                
                Text("Personal Information")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(spacing: 16) {
                EnhancedInfoRow(icon: "person.fill", title: "Username", value: user.username, color: .blue)
                EnhancedInfoRow(icon: "envelope.fill", title: "Email", value: user.email, color: .green)
                EnhancedInfoRow(icon: "person.2.fill", title: "Gender", value: user.gender, color: .orange)
                EnhancedInfoRow(icon: "number.circle.fill", title: "User ID", value: user.userId, color: .purple)
            }
        }
        .padding(25)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
    }
    
    private func statsCard() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                    .font(.headline)
                
                Text("Statistics")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            if let stats = userStats {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 15) {
                    StatCard(icon: "note.text", title: "Posts", value: "\(stats.postCount)", color: .blue)
                    StatCard(icon: "message.fill", title: "Comments", value: "\(stats.commentCount)", color: .green)
                    StatCard(icon: "heart.fill", title: "Total Likes", value: "\(stats.totalLikes)", color: .red)
                    StatCard(icon: "chart.line.uptrend.xyaxis", title: "Engagement", value: "\(stats.postCount + stats.commentCount)", color: .purple)
                }
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 15) {
                    ForEach(0..<4, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 80)
                            .overlay(
                                ProgressView()
                                    .scaleEffect(0.8)
                            )
                    }
                }
            }
        }
        .padding(25)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
    }
    
    private var logoutButton: some View {
        Button(action: {
            showLogoutAlert = true
        }) {
            HStack(spacing: 12) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.headline)
                
                Text("Log Out")
                    .fontWeight(.semibold)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .foregroundColor(.red)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.red.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.red.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal)
        .buttonStyle(ScaleButtonStyle())
    }
    
    private var myCoursesButton: some View {
        NavigationLink(destination: MyCoursesView()) {
            HStack(spacing: 12) {
                Image(systemName: "book.fill")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Text("My Courses")
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.blue.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal)
        .buttonStyle(ScaleButtonStyle())
    }
    
    
    private func loadUserStats() {
        guard let user = currentUser else { return }
        
        FirebaseService.shared.fetchUserStats(userId: user.userId) { stats in
            DispatchQueue.main.async {
                self.userStats = stats
                self.isLoading = false
            }
        }
    }
    
    private func saveUserToLocalStorage(user: User) {
        do {
            let descriptor = FetchDescriptor<User>()
            let allUsers = try modelContext.fetch(descriptor)
            
            if let existingUser = allUsers.first(where: { $0.userId == user.userId }) {
                existingUser.username = user.username
                existingUser.email = user.email
                existingUser.gender = user.gender
            } else {
                modelContext.insert(user)
            }
            try modelContext.save()
        } catch {
        }
    }
    
    private func loadUserByUsername() {
        isLoading = false
        errorMessage = "Please log in again"
    }
    
    private func logout() {
        FirebaseService.shared.logout()
        isLoggedIn = false
        currentUsername = ""
        currentUserId = ""
        currentUser = nil
        userStats = nil
        avatarImage = nil
    }
}

struct EnhancedInfoRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(color.gradient)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
                
                Text(value)
                    .font(.body)
                    .foregroundColor(.primary)
                    .fontWeight(.regular)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(color.opacity(0.1))
                )
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 3)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct GradientButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.horizontal, 25)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .cornerRadius(12)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}



struct UserStats {
    let postCount: Int
    let commentCount: Int
    let totalLikes: Int
}

#Preview {
    ProfileView()
        .modelContainer(for: [User.self])
}
