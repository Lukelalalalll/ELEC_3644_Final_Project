import SwiftUI
import SwiftData

struct FullScreenImageView: View {
    let image: UIImage
    @Binding var isPresented: Bool
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
                            isPresented = false
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
                            isPresented = false
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
    
    @State private var showingFullScreenImage = false
    @State private var selectedImage: UIImage? = nil
    
    // Add this state for keyboard dismissal
    @FocusState private var isCommentFieldFocused: Bool
    
    init(post: Post) {
        self.post = post
        self._likeCount = State(initialValue: post.likes)
        
        let currentUserId = UserDefaults.standard.string(forKey: "currentUserId")
        let isLiked = currentUserId != nil && post.likedByUsers.contains { $0.userId == currentUserId }
        self._liked = State(initialValue: isLiked)
        
        self._comments = State(initialValue: post.comments.sorted { $0.commentDate > $1.commentDate })
    }
    
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

    private var isCurrentUserAuthor: Bool {
        guard let currentUser = currentUser, let postAuthor = post.author else {
            return false
        }
        return currentUser.userId == postAuthor.userId
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
                    post.likedByUsers.removeAll()
                }
                
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
            print("Failed to refresh like status: \(error)")
        }
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
                            Text(post.author?.username ?? "Anonymous")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text(post.formattedDate)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
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
                
                // Error message
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
                            handlePostLike()
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
                            .focused($isCommentFieldFocused) // Add focus state
                        
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
                            Text("Be the first to comment")
                                .font(.caption)
                                .foregroundColor(.secondary.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(comments) { comment in
                                CommentRow(comment: comment, currentUser: currentUser, onDelete: {
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
        .navigationTitle("Post Details")
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
                await refreshLikeStatus()
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
                        isPresented: $showingFullScreenImage
                    )
                    .transition(.opacity)
                    .zIndex(1000)
                }
            }
        )
        // Add tap gesture to dismiss keyboard
        .onTapGesture {
            isCommentFieldFocused = false
        }
    }
    
    private func handlePostLike() {
        guard let user = currentUser else {
            errorMessage = "Please login first"
            showError = true
            return
        }
        
        let wasLiked = liked
        
        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
            if liked {
                post.unlike(by: user)
                liked = false
            } else {
                post.like(by: user)
                liked = true
            }
            likeCount = post.likes
        }
        
        FirebaseService.shared.updatePostLikeStatus(postId: post.postId, userId: user.userId, isLiking: liked) { result in
            DispatchQueue.main.async {
                if case .failure(let error) = result {
                    errorMessage = "Failed to update likes: \(error.localizedDescription)"
                    showError = true
                    
                    let wasLiked = !liked
                    if wasLiked {
                        post.like(by: user)
                    } else {
                        post.unlike(by: user)
                    }
                    liked = wasLiked
                    likeCount = post.likes
                } else {
                    try? modelContext.save()
                }
            }
        }
    }
    
    private func refreshComments() async {
        await MainActor.run {
            isRefreshing = true
        }
        
        await PostDetailView.forceSyncCommentsForPost(post, context: modelContext)
        
        await MainActor.run {
            self.comments = post.comments.sorted { $0.commentDate > $1.commentDate }
            self.likeCount = post.likes
            
            let currentUserId = UserDefaults.standard.string(forKey: "currentUserId")
            self.liked = currentUserId != nil && post.likedByUsers.contains { $0.userId == currentUserId }
            
            self.isRefreshing = false
            print("Refresh completed, comment count: \(self.comments.count)")
        }
    }

    @MainActor
    private func getLocalUser(by userId: String) -> User? {
        do {
            let descriptor = FetchDescriptor<User>(predicate: #Predicate { $0.userId == userId })
            return try modelContext.fetch(descriptor).first
        } catch {
            print("Failed to get local user: \(error)")
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
        
        FirebaseService.shared.addComment(
            postId: post.postId,
            content: trimmedComment,
            author: user
        ) { result in
            DispatchQueue.main.async {
                self.isAddingComment = false
                
                switch result {
                case .success(let firebaseComment):
                    firebaseComment.post = self.post
                    firebaseComment.author = user
                    
                    self.comments.insert(firebaseComment, at: 0)
                    self.post.comments.append(firebaseComment)
                    user.postComments.append(firebaseComment)
                    
                    self.commentText = ""
                    self.showError = false
                    self.isCommentFieldFocused = false // Dismiss keyboard after posting
                    
                    do {
                        self.modelContext.insert(firebaseComment)
                        try self.modelContext.save()
                        print("Comment published successfully, user: \(user.username)")
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
        FirebaseService.shared.deleteComment(commentId: comment.commentId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    withAnimation(.easeInOut(duration: 0.3)) {
                        if let index = self.comments.firstIndex(where: { $0.commentId == comment.commentId }) {
                            self.comments.remove(at: index)
                        }
                        
                        if let postIndex = self.post.comments.firstIndex(where: { $0.commentId == comment.commentId }) {
                            self.post.comments.remove(at: postIndex)
                        }
                        
                        if let author = comment.author,
                           let userCommentIndex = author.postComments.firstIndex(where: { $0.commentId == comment.commentId }) {
                            author.postComments.remove(at: userCommentIndex)
                        }
                        
                        self.modelContext.delete(comment)
                        
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
    
    private func deletePost() {
        FirebaseService.shared.deletePost(postId: post.postId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
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

struct CommentRow: View {
    let comment: PostComment
    let currentUser: User?
    let onDelete: () -> Void
    @State private var liked = false
    @State private var showingDeleteAlert = false
    
    private var isCurrentUserAuthor: Bool {
        guard let currentUserId = UserDefaults.standard.string(forKey: "currentUserId"),
              let commentAuthor = comment.author else {
            return false
        }
        return currentUserId == commentAuthor.userId
    }
    
    private var formattedCommentDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: comment.commentDate)
    }
    
    private func handleCommentLike(comment: PostComment) {
        guard let currentUser = currentUser else {
            print("User not logged in")
            return
        }
        
        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
            if liked {
                comment.unlike(by: currentUser)
                liked = false
            } else {
                comment.like(by: currentUser)
                liked = true
            }
            
            FirebaseService.shared.updateCommentLikes(commentId: comment.commentId, likes: comment.likes) { result in
                DispatchQueue.main.async {
                    if case .failure(let error) = result {
                        print("Failed to update comment likes in Firebase: \(error)")
                        if liked {
                            comment.unlike(by: currentUser)
                            liked = false
                        } else {
                            comment.like(by: currentUser)
                            liked = true
                        }
                    }
                }
            }
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 36, height: 36)
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(comment.author?.username ?? "Anonymous")
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
                    Spacer()
                    
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
            let currentUserId = UserDefaults.standard.string(forKey: "currentUserId")
            liked = currentUserId != nil && comment.likedByUsers.contains { $0.userId == currentUserId }
        }
    }
}

extension PostDetailView {
    static func forceSyncCommentsForPost(_ post: Post, context: ModelContext) async {
        do {
            print("Starting comment sync, post ID: \(post.postId)")
            let firebaseComments = try await FirebaseService.shared.fetchCommentsForPostSync(postId: post.postId)
            print("Retrieved \(firebaseComments.count) comments from Firebase")
            
            await MainActor.run {
                let existingCommentIds = Set(post.comments.map { $0.commentId })
                let newCommentIds = Set(firebaseComments.map { $0.commentId })
                
                print("Local existing comment IDs: \(existingCommentIds)")
                print("Firebase comment IDs: \(newCommentIds)")
                
                var commentsToRemove: [PostComment] = []
                for comment in post.comments {
                    if !newCommentIds.contains(comment.commentId) {
                        commentsToRemove.append(comment)
                        print("Preparing to delete comment: \(comment.commentId)")
                    }
                }
                
                for comment in commentsToRemove {
                    context.delete(comment)
                    if let index = post.comments.firstIndex(where: { $0.commentId == comment.commentId }) {
                        post.comments.remove(at: index)
                    }
                }
                
                var addedCount = 0
                for fbComment in firebaseComments {
                    if !existingCommentIds.contains(fbComment.commentId) {
                        let newComment = PostComment(
                            commentId: fbComment.commentId,
                            content: fbComment.content,
                            author: nil,
                            post: post
                        )
                        newComment.likes = fbComment.likes
                        newComment.commentDate = fbComment.commentDate
                        
                        if let fbAuthor = fbComment.author {
                            if let localUser = getLocalUser(by: fbAuthor.userId, context: context) {
                                newComment.author = localUser
                            } else {
                                let newUser = User(
                                    userId: fbAuthor.userId,
                                    username: fbAuthor.username,
                                    password: "",
                                    email: fbAuthor.email,
                                    gender: fbAuthor.gender
                                )
                                context.insert(newUser)
                                newComment.author = newUser
                            }
                        }
                        
                        context.insert(newComment)
                        post.comments.append(newComment)
                        addedCount += 1
                        print("Added new comment: \(fbComment.commentId)")
                    }
                }
                
                post.comments.sort { $0.commentDate > $1.commentDate }
                
                try? context.save()
                print("Sync completed: deleted \(commentsToRemove.count) comments, added \(addedCount) comments, total \(post.comments.count) comments")
            }
        } catch {
            print("Comment sync failed: \(error)")
        }
    }
    
    @MainActor
    private static func getLocalUser(by userId: String, context: ModelContext) -> User? {
        do {
            let descriptor = FetchDescriptor<User>(predicate: #Predicate { $0.userId == userId })
            return try context.fetch(descriptor).first
        } catch {
            print("Failed to get local user: \(error)")
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
