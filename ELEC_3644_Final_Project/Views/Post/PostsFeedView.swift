//
//  PostsFeedView.swift
//  ELEC_3644_Final_Project
//
//  Created by cccakkke on 2025/11/20.
//

import SwiftUI
import SwiftData

struct PostsFeedView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Post.postDate, order: .reverse) private var posts: [Post]
    @State private var isRefreshing = false
    @State private var showingNewPost = false
    @State private var lastRefreshTime = Date()
    
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
            .onAppear {
                let shouldRefresh = posts.isEmpty ||
                                  Date().timeIntervalSince(lastRefreshTime) > 300 ||
                                  UserDefaults.standard.bool(forKey: "forceRefreshPosts")
                
                if shouldRefresh {
                    Task {
                        await refreshPosts()
                        UserDefaults.standard.set(false, forKey: "forceRefreshPosts")
                    }
                }
            }
        }
    }
    
    private func refreshPosts() async {
        isRefreshing = true
        defer { isRefreshing = false }
        
        do {
            print("开始从 Firebase 强制刷新所有帖子...")
            let firebasePosts = try await fetchPostsFromFirebase()
            
            await MainActor.run {
                updateLocalPosts(with: firebasePosts)
                lastRefreshTime = Date()
                print("成功刷新了 \(firebasePosts.count) 个帖子，包含所有用户的数据")
            }
            
        } catch {
            print("从 Firebase 刷新帖子失败: \(error)")
            
            await MainActor.run {
                if posts.isEmpty {
                    addSamplePosts()
                }
            }
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
            let localPosts = try modelContext.fetch(FetchDescriptor<Post>())
            
            var localPostDict = [String: Post]()
            for post in localPosts {
                localPostDict[post.postId] = post
            }
            
            for firebasePost in firebasePosts {
                if let existingPost = localPostDict[firebasePost.postId] {
                    updateExistingPost(existingPost, with: firebasePost)
                } else {
                    modelContext.insert(firebasePost)
                }
            }
            
            // 删除本地不存在于 Firebase 的帖子
            let firebasePostIds = Set(firebasePosts.map { $0.postId })
            for localPost in localPosts {
                if !firebasePostIds.contains(localPost.postId) {
                    modelContext.delete(localPost)
                }
            }
            
            try modelContext.save()
        } catch {
            print("更新本地帖子失败: \(error)")
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
        existing.likedByUsers = firebase.likedByUsers
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
    
    // 获取当前用户（类似 PostDetailView）
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
    
    // 辅助：异步获取用户
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
    
    // 刷新点赞状态（类似 PostDetailView）
    private func refreshLikeStatus() async {
        do {
            if let data = try await FirebaseService.shared.getPostData(postId: post.postId) {
                let likesFromData = data["likes"] as? Int ?? 0
                let likedByUserIds = data["likedByUserIds"] as? [String] ?? []
                
                await MainActor.run {
                    post.likes = likesFromData
                    post.likedByUsers.removeAll()
                }
                
                // 并发加载用户
                let users = await withTaskGroup(of: User?.self) { group in
                    for userId in likedByUserIds {
                        group.addTask {
                            await self.getUserAsync(userId: userId)
                        }
                    }
                    var collectedUsers: [User] = []
                    for await user in group {
                        if let user = user {
                            collectedUsers.append(user)
                        }
                    }
                    return collectedUsers
                }
                
                await MainActor.run {
                    post.likedByUsers.append(contentsOf: users)
                    likeCount = post.likes
                    let currentUserId = UserDefaults.standard.string(forKey: "currentUserId") ?? ""
                    liked = likedByUserIds.contains(currentUserId)
                    try? modelContext.save()
                }
            }
        } catch {
            print("刷新点赞状态失败: \(error)")
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
                        print("用户未登录，无法点赞")
                        return
                    }
                    
                    let wasLiked = liked  // 记录操作前状态
                    
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
                    
                    // 同步到 Firebase
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
        .onAppear {
            Task {
                await refreshLikeStatus()
            }
        }
    }
    
    private func updateLikesOnServer(wasLiked: Bool) {
        guard let currentUser = currentUser else { return }
        
        let isLiking = !wasLiked  // 因为操作后 liked = !wasLiked
        
        FirebaseService.shared.updatePostLikeStatus(postId: post.postId, userId: currentUser.userId, isLiking: isLiking) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    do {
                        try modelContext.save()
                        print("点赞状态更新成功")
                        // 操作成功后刷新状态，确保同步
                        Task {
                            await refreshLikeStatus()
                        }
                    } catch {
                        print("保存点赞状态到本地失败: \(error)")
                    }
                case .failure(let error):
                    print("更新点赞数到 Firebase 失败: \(error)")
                    // 回滚：基于 wasLiked 恢复
                    if !wasLiked {
                        // 原操作是 like，失败则 unlike
                        post.unlike(by: currentUser)
                        liked = false
                    } else {
                        // 原操作是 unlike，失败则 like
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
