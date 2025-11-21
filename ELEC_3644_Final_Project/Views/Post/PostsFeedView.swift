//
//  PostsView.swift
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
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(posts) { post in
                        NavigationLink {
                            PostDetailView(post: post)
                        } label: {
                            PostCell(post: post)
                        }
                        .buttonStyle(.plain)
                    }
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
            .onAppear {
                if posts.isEmpty {
                    addSamplePosts()
                }
            }
        }
    }
    
    private func addSamplePosts() {
        for post in Post.mockPosts {
            modelContext.insert(post)
        }
        try? modelContext.save()
    }
}

// MARK: - Post Cell
struct PostCell: View {
    let post: Post
    @State private var liked = false
    @State private var likeCount: Int
    
    init(post: Post) {
        self.post = post
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
                
                Button {
                    // 分享功能
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                }
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
