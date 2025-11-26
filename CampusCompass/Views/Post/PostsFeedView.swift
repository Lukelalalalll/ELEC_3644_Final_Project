import SwiftUI
import SwiftData

struct PostsFeedView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Post.postDate, order: .reverse) private var posts: [Post]
    @State private var isRefreshing = false
    @State private var showingNewPost = false
    @State private var lastRefreshTime = Date()
    @State private var refreshID = UUID()
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(posts) { post in
                        NavigationLink {
                            PostDetailView(post: post)
                        } label: {
                            PostCell(post: post, modelContext: modelContext)
                        }
                        .buttonStyle(.plain)
                    }
                    Spacer()
                        .frame(height: 50)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Campus Posts")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: PublishPostView()) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }
            }
            .refreshable {
                await refreshPosts()
            }
        }
        .id(refreshID)
    }
    
    private func refreshPosts() async {
        isRefreshing = true
        defer { isRefreshing = false }
        
        do {
            let firebasePosts = try await fetchPostsFromFirebase()
            await refreshAllPostsLikeStatus(for: firebasePosts)
            
            await MainActor.run {
                updateLocalPosts(with: firebasePosts)
                lastRefreshTime = Date()
                refreshID = UUID()
            }
            
        } catch {
            print("Failed to refresh posts from Firebase: \(error)")
            
            await MainActor.run {
                if posts.isEmpty {
                    addSamplePosts()
                }
            }
        }
    }
    
    
    private func refreshAllPostsLikeStatus(for posts: [Post]) async {
        let currentUserId = UserDefaults.standard.string(forKey: "currentUserId") ?? ""
        
        await withTaskGroup(of: Void.self) { group in
            for post in posts {
                group.addTask {
                    await self.refreshSinglePostLikeStatus(post: post, currentUserId: currentUserId)
                }
            }
        }
    }
        
    private func refreshSinglePostLikeStatus(post: Post, currentUserId: String) async {
        do {
            if let data = try await FirebaseService.shared.getPostData(postId: post.postId) {
                let likesFromData = data["likes"] as? Int ?? 0
                let likedByUserIds = data["likedByUserIds"] as? [String] ?? []
                
                await MainActor.run {
                    post.likes = likesFromData
                    
                    if !currentUserId.isEmpty {
                        print("Post \(post.postId) likes: \(likesFromData), current user liked: \(likedByUserIds.contains(currentUserId))")
                    }
                }
            }
        } catch {
            print("Failed to refresh like status for post \(post.postId): \(error)")
        }
    }
    
    
    private func fetchPostsFromFirebase() async throws -> [Post] {
        return try await withCheckedThrowingContinuation { continuation in
            FirebaseService.shared.fetchPosts { result in
                switch result {
                case .success(let posts):
                    continuation.resume(returning: posts)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    @MainActor
    private func updateLocalPosts(with firebasePosts: [Post]) {
        do {
            // Clear all existing posts from local database
            let localPosts = try modelContext.fetch(FetchDescriptor<Post>())
            for post in localPosts {
                modelContext.delete(post)
            }
            
            // Insert new posts from Firebase
            for firebasePost in firebasePosts {
                modelContext.insert(firebasePost)
            }
            
            try modelContext.save()
            
        } catch {
            print("Failed to update local posts: \(error)")
        }
    }
    
    private func updateExistingPost(_ existing: Post, with firebase: Post) {
        existing.title = firebase.title
        existing.content = firebase.content
        existing.postImage = firebase.postImage
        existing.likes = firebase.likes
        existing.postDate = firebase.postDate
        existing.author = firebase.author
        existing.comments = firebase.comments
        existing.likes = firebase.likes
    }
    
    private func addSamplePosts() {
        for mockPost in Post.mockPosts {
            modelContext.insert(mockPost)
        }
        try? modelContext.save()
    }
}

struct PostCell: View {
    let post: Post
    @Environment(\.modelContext) private var modelContext
    
    @State private var liked: Bool
    @State private var likeCount: Int
    
    private var currentUser: User? {
        guard let currentUserId = UserDefaults.standard.string(forKey: "currentUserId") else {
            return nil
        }
        
        do {
            let existingUsers = try modelContext.fetch(FetchDescriptor<User>())
            return existingUsers.first(where: { $0.userId == currentUserId })
        } catch {
            print("Failed to fetch current user: \(error)")
            return nil
        }
    }
    
    init(post: Post, modelContext: ModelContext) {
        self.post = post
        let currentUserId = UserDefaults.standard.string(forKey: "currentUserId")
        
        let isLiked = currentUserId != nil && post.likedByUsers.contains { $0.userId == currentUserId }
        self._liked = State(initialValue: isLiked)
        self._likeCount = State(initialValue: post.likes)
    }
    

    private func getUserAsync(userId: String) async -> User? {
        await withCheckedContinuation { continuation in
            FirebaseService.shared.getUserData(userId: userId) { result in
                switch result {
                case .success(let user):
                    continuation.resume(returning: user)
                case .failure:
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    private func refreshLikeStatus() async {
        do {
            if let data = try await FirebaseService.shared.getPostData(postId: post.postId) {
                let likesFromData = data["likes"] as? Int ?? 0
                let likedByUserIds = data["likedByUserIds"] as? [String] ?? []
                
                await MainActor.run {
                    post.likes = likesFromData
                    likeCount = likesFromData
                    
                    let currentUserId = UserDefaults.standard.string(forKey: "currentUserId") ?? ""
                    liked = likedByUserIds.contains(currentUserId)
                }
            }
        } catch {
            print("Failed to refresh like status: \(error)")
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 44, height: 44)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.author?.username ?? "Anonymous")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(post.formattedDate)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                if !post.title.isEmpty {
                    Text(post.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Text(post.content)
                    .font(.body)
                    .lineLimit(3)
                    .foregroundColor(.primary)
                    .lineSpacing(2)
            }
            
            // Post Image
            if let imageData = post.postImage,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .cornerRadius(30)
            }
            
            // Stats and Actions
            HStack(spacing: 20) {
                Button {
                    guard let currentUser = currentUser else {
                        print("User not logged in, cannot like post")
                        return
                    }
                    
                    let wasLiked = liked
                    
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        if liked {
                            post.unlike(by: currentUser)
                            liked = false
                        } else {
                            post.like(by: currentUser)
                            liked = true
                        }
                        likeCount = post.likes
                    }
                    
                    updateLikesOnServer(wasLiked: wasLiked)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: liked ? "heart.fill" : "heart")
                            .foregroundColor(liked ? .red : .secondary)
                            .font(.system(size: 18))
                        Text("\(likeCount)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(liked ? .red : .secondary)
                    }
                }
                .disabled(currentUser == nil)
                
                HStack(spacing: 6) {
                    Image(systemName: "message")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                    Text("\(post.commentCount)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.top, 4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .stroke(Color(.systemGray5), lineWidth: 0.5)
        )
    }
    
    private func updateLikesOnServer(wasLiked: Bool) {
        guard let currentUser = currentUser else { return }
        
        let isLiking = !wasLiked
        
        FirebaseService.shared.updatePostLikeStatus(postId: post.postId, userId: currentUser.userId, isLiking: isLiking) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    do {
                        try modelContext.save()
                        print("Like status updated successfully")
                        Task {
                            await refreshLikeStatus()
                        }
                    } catch {
                        print("Failed to save like status to local database: \(error)")
                    }
                case .failure(let error):
                    print("Failed to update likes on Firebase: \(error)")
                    if !wasLiked {
                        post.unlike(by: currentUser)
                        liked = false
                    } else {
                        post.like(by: currentUser)
                        liked = true
                    }
                    likeCount = post.likes
                }
            }
        }
    }
}

#Preview {
    PostsFeedView()
        .modelContainer(for: [Post.self, User.self, PostComment.self])
}
