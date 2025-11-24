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
                    
                    if let firebaseAuthor = firebasePost.author {
                        linkOrCreateUser(firebaseAuthor)
                        firebasePost.author = getLocalUser(by: firebaseAuthor.userId) ?? firebaseAuthor
                    }
                    
                    for comment in firebasePost.comments {
                        modelContext.insert(comment)
                        comment.post = firebasePost
                        
                        if let commentAuthor = comment.author {
                            linkOrCreateUser(commentAuthor)
                            comment.author = getLocalUser(by: commentAuthor.userId) ?? commentAuthor
                        }
                    }
                }
            }
            
            let firebasePostIds = Set(firebasePosts.map { $0.postId })
            for localPost in localPosts {
                if !firebasePostIds.contains(localPost.postId) {
                    modelContext.delete(localPost)
                }
            }
            
            try modelContext.save()
            
            print("本地数据库更新完成，现有 \(firebasePosts.count) 个帖子")
            
        } catch {
            print("更新本地帖子失败: \(error)")
        }
    }
    
    @MainActor
    private func updateExistingPost(_ existingPost: Post, with firebasePost: Post) {
        // 基本信息更新
        existingPost.title = firebasePost.title
        existingPost.content = firebasePost.content
        existingPost.likes = firebasePost.likes
        existingPost.postDate = firebasePost.postDate
        existingPost.postImage = firebasePost.postImage
        
        if let firebaseAuthor = firebasePost.author {
            linkOrCreateUser(firebaseAuthor)
            existingPost.author = getLocalUser(by: firebaseAuthor.userId) ?? firebaseAuthor
        }
        
        syncAllComments(for: existingPost, from: firebasePost.comments)
    }
    
    // MARK: - 用户管理辅助方法
    @MainActor
    private func linkOrCreateUser(_ firebaseUser: User) {
        if getLocalUser(by: firebaseUser.userId) == nil {
            let newUser = User(
                userId: firebaseUser.userId,
                username: firebaseUser.username,
                password: "", // 不存储密码
                email: firebaseUser.email,
                gender: firebaseUser.gender,
                avatar: firebaseUser.avatar
            )
            newUser.joinDate = firebaseUser.joinDate
            modelContext.insert(newUser)
        } else {
            // 用户已存在，更新信息
            if let existingUser = getLocalUser(by: firebaseUser.userId) {
                existingUser.username = firebaseUser.username
                existingUser.email = firebaseUser.email
                existingUser.gender = firebaseUser.gender
                existingUser.avatar = firebaseUser.avatar
            }
        }
    }
    
    @MainActor
    private func getLocalUser(by userId: String) -> User? {
        do {
            let existingUsers = try modelContext.fetch(FetchDescriptor<User>())
            return existingUsers.first(where: { $0.userId == userId })
        } catch {
            print("获取本地用户失败: \(error)")
            return nil
        }
    }
    
    // MARK: - 彻底同步评论（修复跨账号看不见评论的核心函数）
    @MainActor
    private func syncAllComments(for post: Post, from firebaseComments: [PostComment]) {
        // 1. 创建映射以便快速查找
        var localCommentMap = [String: PostComment]()
        for comment in post.comments {
            localCommentMap[comment.commentId] = comment
        }
        
        let firebaseCommentIds = Set(firebaseComments.map { $0.commentId })
        
        // 2. 删除本地多余的评论
        for localComment in post.comments {
            if !firebaseCommentIds.contains(localComment.commentId) {
                // 从关联关系中移除
                post.comments.removeAll { $0.commentId == localComment.commentId }
                if let author = localComment.author {
                    author.postComments.removeAll { $0.commentId == localComment.commentId }
                }
                // 从数据库中删除
                modelContext.delete(localComment)
            }
        }
        
        // 3. 更新或添加评论
        for firebaseComment in firebaseComments {
            if let existingComment = localCommentMap[firebaseComment.commentId] {
                // 更新现有评论
                existingComment.content = firebaseComment.content
                existingComment.likes = firebaseComment.likes
                existingComment.commentDate = firebaseComment.commentDate
                
                // 更新评论作者
                if let fbAuthor = firebaseComment.author {
                    linkOrCreateUser(fbAuthor)
                    existingComment.author = getLocalUser(by: fbAuthor.userId) ?? fbAuthor
                }
            } else {
                // 添加新评论
                let newComment = PostComment(
                    commentId: firebaseComment.commentId,
                    content: firebaseComment.content,
                    author: nil,
                    post: post
                )
                newComment.likes = firebaseComment.likes
                newComment.commentDate = firebaseComment.commentDate
                
                // 设置评论作者
                if let fbAuthor = firebaseComment.author {
                    linkOrCreateUser(fbAuthor)
                    newComment.author = getLocalUser(by: fbAuthor.userId) ?? fbAuthor
                }
                
                modelContext.insert(newComment)
                post.comments.append(newComment)
                
                // 添加到作者的关系中
                if let author = newComment.author {
                    if !author.postComments.contains(where: { $0.commentId == newComment.commentId }) {
                        author.postComments.append(newComment)
                    }
                }
            }
        }
    }
    
    // 保留示例帖子作为后备
    private func addSamplePosts() {
        // 获取或创建示例用户
        let sampleUser: User
        
        do {
            let existingUsers = try modelContext.fetch(FetchDescriptor<User>())
            if let existingUser = existingUsers.first(where: { $0.username == "sample_user" }) {
                sampleUser = existingUser
            } else {
                sampleUser = User(
                    userId: UUID().uuidString,
                    username: "sample_user",
                    password: "password",
                    email: "sample@example.com",
                    gender: "Male"
                )
                modelContext.insert(sampleUser)
            }
            
            // 创建示例帖子并关联用户
            for post in Post.mockPosts {
                post.author = sampleUser
                sampleUser.posts.append(post)
                modelContext.insert(post)
            }
            
            try modelContext.save()
            print("添加了 \(Post.mockPosts.count) 个示例帖子")
        } catch {
            print("添加示例帖子失败: \(error)")
        }
    }
    
    // 公开刷新方法，允许外部调用
    func refreshPostsIfNeeded() async {
        await refreshPosts()
    }
}

// MARK: - Post Cell
struct PostCell: View {
    let post: Post
    let modelContext: ModelContext
    @State private var liked = false
    @State private var likeCount: Int
    
    init(post: Post, modelContext: ModelContext) {
        self.post = post
        self.modelContext = modelContext
        self._likeCount = State(initialValue: post.likes)
        self._liked = State(initialValue: post.likes > 0)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(post.author?.username ?? "Anonymous User")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    Text(post.formattedDate)
                        .font(.caption)
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
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        liked.toggle()
                        likeCount += liked ? 1 : -1
                        post.likes = likeCount
                        
                        // 关键修复：立即同步到 Firebase 并保存到本地
                        FirebaseService.shared.updatePostLikes(postId: post.postId, likes: likeCount) { result in
                            DispatchQueue.main.async {
                                switch result {
                                case .success:
                                    // 保存到本地数据库
                                    do {
                                        try modelContext.save()
                                    } catch {
                                        print("Failed to save likes locally: \(error)")
                                    }
                                case .failure(let error):
                                    print("更新点赞数到 Firebase 失败: \(error)")
                                    // 回滚点赞操作
                                    liked.toggle()
                                    likeCount += liked ? -1 : 1
                                    post.likes = likeCount
                                }
                            }
                        }
                    }
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
    
}

#Preview {
    PostsFeedView()
        .modelContainer(for: [Post.self, User.self, PostComment.self])
}
