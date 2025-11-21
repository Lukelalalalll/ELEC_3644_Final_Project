//
//  PostDetailView.swift
//  ELEC_3644_Final_Project
//
//  Created by cccakkke on 2025/11/21.
//

import SwiftUI
import SwiftData

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
    
    init(post: Post) {
        self.post = post
        self._likeCount = State(initialValue: post.likes)
        self._liked = State(initialValue: post.likes > 0)
    }
    
    // 获取当前用户的方法
    private var currentUser: User? {
        guard let currentUsername = UserDefaults.standard.string(forKey: "currentUsername") else {
            return nil
        }
        
        let predicate = #Predicate<User> { user in
            user.username == currentUsername
        }
        
        let descriptor = FetchDescriptor<User>(predicate: predicate)
        
        do {
            let users = try modelContext.fetch(descriptor)
            return users.first
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
        return currentUser.username == postAuthor.username
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
                    }
                    
                    // Stats
                    HStack(spacing: 24) {
                        HStack(spacing: 6) {
                            Image(systemName: liked ? "heart.fill" : "heart")
                                .foregroundColor(liked ? .red : .secondary)
                            Text("\(likeCount)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(liked ? .red : .secondary)
                        }
                        
                        HStack(spacing: 6) {
                            Image(systemName: "message")
                                .foregroundColor(.secondary)
                            Text("\(post.commentCount)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.top, 8)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 22)
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
                                try? modelContext.save()
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
                            Image(systemName: "paperplane.circle.fill")
                                .font(.title2)
                                .foregroundColor(commentText.isEmpty ? .secondary : .blue)
                        }
                        .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
                    Text("Comment (\(post.commentCount))")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 16)
                    
                    if post.comments.isEmpty {
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
                            ForEach(post.comments) { comment in
                                CommentRow(comment: comment, onDelete: {
                                    deleteComment(comment)
                                })
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("帖子详情")
        .navigationBarTitleDisplayMode(.inline)
        // 移除导航栏右侧的工具栏按钮
        .alert("Delete Post", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deletePost()
            }
        } message: {
            Text("Are you sure you want to delete this post? This action cannot be undone.")
        }
    }
    
    // 统一的 addComment 方法
    private func addComment() {
        let trimmedComment = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedComment.isEmpty else { return }
        
        guard let user = currentUser else {
            errorMessage = "Please log in to comment"
            showError = true
            return
        }
        
        let newComment = PostComment(
            commentId: UUID().uuidString,
            content: trimmedComment,
            author: user,
            post: post
        )
        
        // 双向关联
        post.comments.append(newComment)
        user.postComments.append(newComment)
        
        commentText = ""
        showError = false
        
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to save comment"
            showError = true
            print("Failed to save comment: \(error)")
        }
    }
    
    private func deleteComment(_ comment: PostComment) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if let index = post.comments.firstIndex(where: { $0.id == comment.id }) {
                // 从帖子中移除评论
                post.comments.remove(at: index)
                
                if let author = comment.author,
                   let userCommentIndex = author.postComments.firstIndex(where: { $0.id == comment.id }) {
                    author.postComments.remove(at: userCommentIndex)
                }
                
                try? modelContext.save()
            }
        }
    }
    
    // 删除帖子的方法
    private func deletePost() {
        // 由于设置了 @Relationship(deleteRule: .cascade)，删除帖子会自动删除关联的评论
        modelContext.delete(post)
        
        do {
            try modelContext.save()
            dismiss() // 删除成功后返回上一页
        } catch {
            errorMessage = "Failed to delete post"
            showError = true
            print("Failed to delete post: \(error)")
        }
    }
}

// MARK: - Comment Row
struct CommentRow: View {
    let comment: PostComment
    let onDelete: () -> Void
    @State private var liked = false
    @State private var showingDeleteAlert = false
    
    // 检查当前用户是否是评论的作者
    private var isCurrentUserAuthor: Bool {
        guard let currentUsername = UserDefaults.standard.string(forKey: "currentUsername"),
              let commentAuthor = comment.author else {
            return false
        }
        return currentUsername == commentAuthor.username
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
                    
                    // 修改这里：从相对时间改为具体日期时间
                    Text(formattedCommentDate)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Text(comment.content)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: 16) {
                    Button {
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                            liked.toggle()
                            if liked {
                                comment.like()
                            } else {
                                comment.unlike()
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
    }
}

#Preview {
    NavigationView {
        PostDetailView(post: Post.mockPosts[0])
            .modelContainer(for: [Post.self, User.self, PostComment.self])
    }
}
