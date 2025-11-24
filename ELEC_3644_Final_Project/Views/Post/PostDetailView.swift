//
//  PostDetailView.swift
//  ELEC_3644_Final_Project
//
//  Created by cccakkke on 2025/11/21.
//

import SwiftUI
import SwiftData


struct FullScreenImageView: View {
    let image: UIImage
    @Binding var isPresented: Bool  // 改为绑定状态
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        Color.black
            .ignoresSafeArea()
            .overlay(
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .animation(.easeInOut(duration: 0.2), value: scale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = min(max(value, 1.0), 4.0)
                            }
                            .onEnded { _ in
                                if scale < 1.0 {
                                    withAnimation {
                                        scale = 1.0
                                    }
                                }
                            }
                    )
                    .gesture(
                        TapGesture(count: 2)
                            .onEnded {
                                withAnimation {
                                    scale = scale > 1.0 ? 1.0 : 2.0
                                }
                            }
                    )
                    .onTapGesture {
                        if scale == 1.0 {
                            isPresented = false  // 使用绑定状态
                        } else {
                            withAnimation {
                                scale = 1.0
                            }
                        }
                    }
            )
            .overlay(
                VStack {
                    HStack {
                        Button {
                            isPresented = false  // 使用绑定状态
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .padding()
                                .background(Circle().fill(Color.black.opacity(0.3)))
                        }
                        Spacer()
                    }
                    .padding(.top, 50)
                    .padding(.leading, 16)
                    Spacer()
                }
            )
            .statusBar(hidden: true)
            .onAppear {
                print("FullScreenImageView appeared - overlay version")
                DispatchQueue.main.async {
                    self.scale = 1.0
                }
            }
    }
}



struct PostDetailView: View {
    let post: Post
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var commentText = ""
    @State private var liked = false
    @State private var likeCount: Int
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showingDeleteAlert = false
    @State private var comments: [PostComment] = []
    @State private var isAddingComment = false
    @State private var isRefreshing = false
    
    
    
    // 添加全屏图片预览状态
    @State private var showingFullScreenImage = false
    @State private var selectedImage: UIImage? = nil
    
    init(post: Post) {
        self.post = post
        self._likeCount = State(initialValue: post.likes)
        self._liked = State(initialValue: post.likes > 0)
        self._comments = State(initialValue: post.comments.sorted { $0.commentDate > $1.commentDate })
    }
    
    // 获取当前用户的方法
    private var currentUser: User? {
        guard let currentUserId = UserDefaults.standard.string(forKey: "currentUserId") else {
            return nil
        }
        
        // 使用 userId 查找用户
        do {
            let existingUsers = try modelContext.fetch(FetchDescriptor<User>())
            return existingUsers.first(where: { $0.userId == currentUserId })
        } catch {
            print("Failed to fetch current user: \(error)")
            return nil
        }
    }

    // 检查当前用户是否是帖子的作者
    private var isCurrentUserAuthor: Bool {
        guard let currentUser = currentUser, let postAuthor = post.author else {
            return false
        }
        return currentUser.userId == postAuthor.userId
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Post Content Card
                VStack(alignment: .leading, spacing: 16) {
                    // Header
                    HStack(spacing: 12) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 44, height: 44)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(post.author?.username ?? "匿名用户")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text(post.formattedDate)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // 如果是作者，显示删除按钮
                        if isCurrentUserAuthor {
                            Button(role: .destructive) {
                                showingDeleteAlert = true
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 16))
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // Title
                    if !post.title.isEmpty {
                        Text(post.title)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    // Content
                    Text(post.content)
                        .font(.body)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    // Post Image

                    if let imageData = post.postImage,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .cornerRadius(30)
                            .onTapGesture {
                                // 确保在主线程执行
                                DispatchQueue.main.async {
                                    selectedImage = uiImage
                                    showingFullScreenImage = true
                                }
                            }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color(.systemBackground))
                )
                .padding(.horizontal, 16)
                
                // 错误提示
                if showError {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                // Comment Input Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Like       Publish your comment")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 12) {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                liked.toggle()
                                likeCount += liked ? 1 : -1
                                post.likes = likeCount
                                
                                // 同步到 Firebase
                                FirebaseService.shared.updatePostLikes(postId: post.postId, likes: likeCount) { result in
                                    DispatchQueue.main.async {
                                        switch result {
                                        case .success:
                                            // 保存到本地
                                            do {
                                                try modelContext.save()
                                            } catch {
                                                print("Failed to save likes locally: \(error)")
                                            }
                                        case .failure(let error):
                                            print("Failed to update likes in Firebase: \(error)")
                                            // 回滚点赞操作
                                            liked.toggle()
                                            likeCount += liked ? -1 : 1
                                            post.likes = likeCount
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: liked ? "heart.fill" : "heart")
                                    .font(.title2)
                                    .foregroundColor(liked ? .red : .secondary)
                                Text("\(likeCount)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(liked ? .red : .secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        
                        TextField("You can write down your comment here...", text: $commentText, axis: .vertical)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(30)
                            .lineLimit(1...4)
                        
                        Button {
                            addComment()
                        } label: {
                            if isAddingComment {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "paperplane.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(commentText.isEmpty ? .secondary : .blue)
                            }
                        }
                        .disabled(commentText.isEmpty || isAddingComment)
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 22)
                        .fill(Color(.systemBackground))
                )
                .padding(.horizontal, 16)
                
                // Comments Section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Comment (\(comments.count))")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        if isRefreshing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    if comments.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "bubble.left")
                                .font(.system(size: 44))
                                .foregroundColor(.secondary.opacity(0.5))
                            Text("No comments yet")
                                .font(.body)
                                .foregroundColor(.secondary)
                            Text("成为第一个评论的人")
                                .font(.caption)
                                .foregroundColor(.secondary.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(comments) { comment in
                                CommentRow(comment: comment, onDelete: {
                                    deleteComment(comment)
                                })
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                Spacer()
                    .frame(height: 50)
            }
            .padding(.vertical, 8)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("帖子详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    Task {
                        await refreshComments()
                    }
                }) {
                    if isRefreshing {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .disabled(isRefreshing)
            }
        }
        .onAppear {
            Task {
                await refreshComments()
            }
        }
        .alert("Delete Post", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deletePost()
            }
        } message: {
            Text("Are you sure you want to delete this post? This action cannot be undone.")
        }
        .overlay(
            Group {
                if showingFullScreenImage, let image = selectedImage {
                    FullScreenImageView(
                        image: image,
                        isPresented: $showingFullScreenImage  // 传递绑定状态
                    )
                    .transition(.opacity)
                    .zIndex(1000)
                }
            }
        )
    }
    
    private func refreshComments() async {
        await MainActor.run {
            isRefreshing = true
        }
        
        // 使用正确的扩展名
        await PostDetailView.forceSyncCommentsForPost(post, context: modelContext)
        
        await MainActor.run {
            // 更新 @State 变量
            self.comments = post.comments.sorted { $0.commentDate > $1.commentDate }
            self.likeCount = post.likes
            self.liked = post.likes > 0
            self.isRefreshing = false
            print("刷新完成，评论数量: \(self.comments.count)")
        }
    }

    // 添加辅助方法
    @MainActor
    private func getLocalUser(by userId: String) -> User? {
        do {
            let descriptor = FetchDescriptor<User>(predicate: #Predicate { $0.userId == userId })
            return try modelContext.fetch(descriptor).first
        } catch {
            print("获取本地用户失败: \(error)")
            return nil
        }
    }
    
    private func addComment() {
        let trimmedComment = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedComment.isEmpty else { return }
        
        guard let user = currentUser else {
            errorMessage = "Please log in to comment"
            showError = true
            return
        }
        
        isAddingComment = true
        
        // 直接上传到 Firebase，成功后添加到本地
        FirebaseService.shared.addComment(
            postId: post.postId,
            content: trimmedComment,
            author: user
        ) { result in
            DispatchQueue.main.async {
                self.isAddingComment = false
                
                switch result {
                case .success(let firebaseComment):
                    // 设置评论的关联关系
                    firebaseComment.post = self.post
                    firebaseComment.author = user
                    
                    // 添加到本地评论列表
                    self.comments.insert(firebaseComment, at: 0)
                    self.post.comments.append(firebaseComment)
                    user.postComments.append(firebaseComment)
                    
                    self.commentText = ""
                    self.showError = false
                    
                    // 保存到本地
                    do {
                        self.modelContext.insert(firebaseComment)
                        try self.modelContext.save()
                        print("评论发布成功，用户: \(user.username)")
                    } catch {
                        print("Failed to save comment locally: \(error)")
                    }
                    
                case .failure(let error):
                    self.errorMessage = "Failed to add comment: \(error.localizedDescription)"
                    self.showError = true
                }
            }
        }
    }
    
    private func deleteComment(_ comment: PostComment) {
        // 从 Firebase 删除
        FirebaseService.shared.deleteComment(commentId: comment.commentId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    withAnimation(.easeInOut(duration: 0.3)) {
                        // 从本地评论列表中移除
                        if let index = self.comments.firstIndex(where: { $0.commentId == comment.commentId }) {
                            self.comments.remove(at: index)
                        }
                        
                        // 从帖子的评论列表中移除
                        if let postIndex = self.post.comments.firstIndex(where: { $0.commentId == comment.commentId }) {
                            self.post.comments.remove(at: postIndex)
                        }
                        
                        // 从作者的评论列表中移除
                        if let author = comment.author,
                           let userCommentIndex = author.postComments.firstIndex(where: { $0.commentId == comment.commentId }) {
                            author.postComments.remove(at: userCommentIndex)
                        }
                        
                        // 从数据库中删除
                        self.modelContext.delete(comment)
                        
                        // 保存更改
                        do {
                            try self.modelContext.save()
                        } catch {
                            print("Failed to save after comment deletion: \(error)")
                        }
                    }
                    
                case .failure(let error):
                    print("Failed to delete comment from Firebase: \(error)")
                }
            }
        }
    }
    
    // 更新删除帖子功能
    private func deletePost() {
        // 从 Firebase 删除
        FirebaseService.shared.deletePost(postId: post.postId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    // 从本地删除
                    self.modelContext.delete(self.post)
                    do {
                        try self.modelContext.save()
                        self.dismiss()
                    } catch {
                        self.errorMessage = "Failed to delete post locally"
                        self.showError = true
                    }
                    
                case .failure(let error):
                    self.errorMessage = "Failed to delete post: \(error.localizedDescription)"
                    self.showError = true
                }
            }
        }
    }
}

// MARK: - Comment Row (保持不变)
struct CommentRow: View {
    let comment: PostComment
    let onDelete: () -> Void
    @State private var liked = false
    @State private var showingDeleteAlert = false
    
    // 检查当前用户是否是评论的作者
    private var isCurrentUserAuthor: Bool {
        guard let currentUserId = UserDefaults.standard.string(forKey: "currentUserId"),
              let commentAuthor = comment.author else {
            return false
        }
        return currentUserId == commentAuthor.userId
    }
    
    // 格式化评论日期
    private var formattedCommentDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: comment.commentDate)
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 36, height: 36)
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(comment.author?.username ?? "匿名用户")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text(formattedCommentDate)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Text(comment.content)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: 16) {
                    // 评论点赞功能
                    Button {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                            liked.toggle()
                            if liked {
                                comment.like()
                            } else {
                                comment.unlike()
                            }
                            
                            // 同步到 Firebase
                            FirebaseService.shared.updateCommentLikes(commentId: comment.commentId, likes: comment.likes) { result in
                                DispatchQueue.main.async {
                                    if case .failure(let error) = result {
                                        print("Failed to update comment likes in Firebase: \(error)")
                                        // 回滚点赞操作
                                        liked.toggle()
                                        if liked {
                                            comment.unlike()
                                        } else {
                                            comment.like()
                                        }
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: liked ? "heart.fill" : "heart")
                                .font(.caption)
                                .foregroundColor(liked ? .red : .secondary)
                            Text("\(comment.likes)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(liked ? .red : .secondary)
                        }
                    }
                    
                    Button("回复") {
                        // 回复功能
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // 删除按钮 - 只有评论的作者才能看到
                    if isCurrentUserAuthor {
                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .alert("Delete Comment", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete this comment? This action cannot be undone.")
        }
        .onAppear {
            // 初始化点赞状态
            liked = comment.likes > 0
        }
    }
}

// MARK: - 评论同步扩展 - 修复版本
extension PostDetailView {
    static func forceSyncCommentsForPost(_ post: Post, context: ModelContext) async {
        do {
            print("开始同步评论，帖子ID: \(post.postId)")
            let firebaseComments = try await FirebaseService.shared.fetchCommentsForPostSync(postId: post.postId)
            print("从Firebase获取到 \(firebaseComments.count) 条评论")
            
            await MainActor.run {
                // 创建评论ID映射
                let existingCommentIds = Set(post.comments.map { $0.commentId })
                let newCommentIds = Set(firebaseComments.map { $0.commentId })
                
                print("本地已有评论ID: \(existingCommentIds)")
                print("Firebase返回评论ID: \(newCommentIds)")
                
                // 只删除真正不存在的评论
                var commentsToRemove: [PostComment] = []
                for comment in post.comments {
                    if !newCommentIds.contains(comment.commentId) {
                        commentsToRemove.append(comment)
                        print("准备删除评论: \(comment.commentId)")
                    }
                }
                
                // 执行删除
                for comment in commentsToRemove {
                    context.delete(comment)
                    if let index = post.comments.firstIndex(where: { $0.commentId == comment.commentId }) {
                        post.comments.remove(at: index)
                    }
                }
                
                // 添加新评论
                var addedCount = 0
                for fbComment in firebaseComments {
                    if !existingCommentIds.contains(fbComment.commentId) {
                        // 只添加新评论，不更新现有评论
                        let newComment = PostComment(
                            commentId: fbComment.commentId,
                            content: fbComment.content,
                            author: nil,
                            post: post
                        )
                        newComment.likes = fbComment.likes
                        newComment.commentDate = fbComment.commentDate
                        
                        // 处理作者信息
                        if let fbAuthor = fbComment.author {
                            if let localUser = getLocalUser(by: fbAuthor.userId, context: context) {
                                newComment.author = localUser
                            } else {
                                let newUser = User(
                                    userId: fbAuthor.userId,
                                    username: fbAuthor.username,
                                    password: "",
                                    email: fbAuthor.email ?? "",
                                    gender: fbAuthor.gender ?? "Unknown"
                                )
                                context.insert(newUser)
                                newComment.author = newUser
                            }
                        }
                        
                        context.insert(newComment)
                        post.comments.append(newComment)
                        addedCount += 1
                        print("添加新评论: \(fbComment.commentId)")
                    }
                }
                
                // 重新排序评论
                post.comments.sort { $0.commentDate > $1.commentDate }
                
                try? context.save()
                print("同步完成：删除了 \(commentsToRemove.count) 条评论，添加了 \(addedCount) 条评论，总共 \(post.comments.count) 条评论")
            }
        } catch {
            print("评论同步失败：\(error)")
        }
    }
    
    // 辅助方法：通过用户ID获取本地用户
    @MainActor
    private static func getLocalUser(by userId: String, context: ModelContext) -> User? {
        do {
            let descriptor = FetchDescriptor<User>(predicate: #Predicate { $0.userId == userId })
            return try context.fetch(descriptor).first
        } catch {
            print("获取本地用户失败: \(error)")
            return nil
        }
    }
}

#Preview {
    NavigationView {
        PostDetailView(post: Post.mockPosts[0])
            .modelContainer(for: [Post.self, User.self, PostComment.self])
    }
}
