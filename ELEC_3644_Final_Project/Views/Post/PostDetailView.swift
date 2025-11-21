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
    
    init(post: Post) {
        self.post = post
        self._likeCount = State(initialValue: post.likes)
        self._liked = State(initialValue: post.likes > 0)
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
                            .cornerRadius(22)
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
                
                // Comment Input Card - 添加卡片效果
                VStack(alignment: .leading, spacing: 16) {
                    Text("Publish your comment")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 12) {
                        TextField("You can write down your comment here...", text: $commentText, axis: .vertical)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
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
                    Text("评论 (\(post.commentCount))")
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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        liked.toggle()
                        likeCount += liked ? 1 : -1
                        post.likes = likeCount
                        try? modelContext.save()
                    }
                } label: {
                    Image(systemName: liked ? "heart.fill" : "heart")
                        .foregroundColor(liked ? .red : .primary)
                        .font(.system(size: 18))
                }
            }
        }
    }
    
    private func addComment() {
        let trimmedComment = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedComment.isEmpty else { return }
        
        let newComment = PostComment(
            commentId: UUID().uuidString,
            content: trimmedComment,
            post: post
        )
        
        post.comments.append(newComment)
        commentText = ""
        
        try? modelContext.save()
    }
    
    private func deleteComment(_ comment: PostComment) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if let index = post.comments.firstIndex(where: { $0.id == comment.id }) {
                post.comments.remove(at: index)
                try? modelContext.save()
            }
        }
    }
}

// MARK: - Comment Row
struct CommentRow: View {
    let comment: PostComment
    let onDelete: () -> Void
    @State private var liked = false
    @State private var showingDeleteAlert = false
    
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
                    
                    Text(comment.commentDate, style: .relative)
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
                    
                    // 删除按钮
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
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .alert("删除评论", isPresented: $showingDeleteAlert) {
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
