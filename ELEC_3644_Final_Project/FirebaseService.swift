//
// FirebaseService.swift
//ELEC_3644_Final_Project
// Created by cccakkke on 2025/11/21.


import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import SwiftData

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    
    let db = Firestore.firestore()
    
    // 注册用户
    func registerUser(username: String, email: String, password: String, gender: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let user = authResult?.user else {
                completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User creation failed"])))
                return
            }
            
            // 在 Firestore 中保存用户资料 - 包含 avatar 字段
            let userData: [String: Any] = [
                "userId": user.uid,
                "username": username,
                "email": email,
                "gender": gender,
                "avatarURL": "", // 添加空的 avatar 字段
                "joinDate": Timestamp(date: Date()),
                "enrolledCourseIds": []
            ]
            
            self.db.collection("users").document(user.uid).setData(userData) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    // 创建本地 User 对象（不存储密码）
                    let localUser = User(
                        userId: user.uid,
                        username: username,
                        password: "", // 不在本地存储密码
                        email: email,
                        gender: gender,
                        enrolledCourseIds: []
                    )
                    completion(.success(localUser))
                }
            }
        }
    }
    
    // 登录用户
    func loginUser(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let user = authResult?.user else {
                completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Login failed"])))
                return
            }
            
            // 从 Firestore 获取用户资料
            self.getUserData(userId: user.uid) { result in
                completion(result)
            }
        }
    }
    
    // 获取用户资料
    // 在 FirebaseService.swift 中修复 getUserData 方法
    func getUserData(userId: String, completion: @escaping (Result<User, Error>) -> Void) {
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let document = document, document.exists,
                  let data = document.data() else {
                completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User data not found"])))
                return
            }
            
            let username = data["username"] as? String ?? ""
            let email = data["email"] as? String ?? ""
            let gender = data["gender"] as? String ?? "Male"
            let avatarURL = data["avatarURL"] as? String ?? "" // 获取 Storage URL
            let enrolledCourseIds = data["enrolledCourseIds"] as? [String] ?? []
            let user = User(
                userId: userId,
                username: username,
                password: "", // 不在本地存储密码
                email: email,
                gender: gender,
                enrolledCourseIds: enrolledCourseIds
            )
            
            print("ℹ️ User avatarURL from Firestore: \(avatarURL)")
            
            completion(.success(user))
        }
    }
    
    // 检查用户名是否唯一
    func checkUsernameUnique(_ username: String, completion: @escaping (Bool) -> Void) {
        db.collection("users")
            .whereField("username", isEqualTo: username)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error checking username: \(error)")
                    completion(false)
                    return
                }
                
                completion(snapshot?.documents.isEmpty ?? true)
            }
    }
    
    // 登出
    func logout() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error)")
        }
    }
    
    // 获取当前用户 - 这个方法应该已经存在了！
    // 在 FirebaseService.swift 中修改 getCurrentUser 方法
    func getCurrentUser(completion: @escaping (User?) -> Void) {
        print("getCurrentUser called, checking Auth current user...")
        
        if let currentUser = Auth.auth().currentUser {
            print("Auth current user found: \(currentUser.uid)")
            self.getUserData(userId: currentUser.uid) { result in
                switch result {
                case .success(let user):
                    print("Successfully loaded user data: \(user.username)")
                    print("Enrolled courses: \(user.enrolledCourseIds)")
                    completion(user)
                case .failure(let error):
                    print("Failed to load user data from Firestore: \(error)")
                    completion(nil)
                }
            }
        } else {
            print("No Auth current user found")
            completion(nil)
        }
    }
}
// 在 FirebaseService.swift 中添加这些方法

// MARK: - Post 相关方法
extension FirebaseService {
    
    // 发布帖子到 Firebase
    // 发布帖子到 Firebase（支持图片）
    func publishPost(title: String, content: String, imageData: Data? = nil, author: User, completion: @escaping (Result<Post, Error>) -> Void) {
        let postId = UUID().uuidString
        
        // 如果有图片，先上传图片
        if let imageData = imageData {
            uploadPostImage(postId: postId, imageData: imageData) { [weak self] result in
                switch result {
                case .success(let imageURL):
                    // 图片上传成功，发布包含图片URL的帖子
                    self?.createPostInFirestore(
                        postId: postId,
                        title: title,
                        content: content,
                        imageURL: imageURL,
                        author: author,
                        completion: completion
                    )
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else {
            // 没有图片，直接发布帖子
            createPostInFirestore(
                postId: postId,
                title: title,
                content: content,
                imageURL: nil,
                author: author,
                completion: completion
            )
        }
    }

    // 辅助方法：在 Firestore 中创建帖子
    private func createPostInFirestore(postId: String, title: String, content: String, imageURL: String?, author: User, completion: @escaping (Result<Post, Error>) -> Void) {
        var postData: [String: Any] = [
            "postId": postId,
            "title": title,
            "content": content,
            "likes": 0,
            "postDate": Timestamp(date: Date()),
            "authorId": author.userId,
            "authorUsername": author.username,
            "likedByUserIds": []
        ]
        
        // 如果有图片URL，添加到数据中
        if let imageURL = imageURL {
            postData["imageURL"] = imageURL
        }
        
        db.collection("posts").document(postId).setData(postData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                // 创建本地 Post 对象
                let post = Post(
                    postId: postId,
                    title: title,
                    content: content,
                    postImage: nil, // 不直接存储图片数据
                    author: author
                )
                
                // 如果有图片URL，稍后下载
                if let imageURL = imageURL {
                    // 异步下载图片到本地
                    self.downloadAndCachePostImage(postId: postId) { imageData in
                        post.postImage = imageData
                    }
                }
                
                completion(.success(post))
            }
        }
    }

    // 下载并缓存帖子图片
    private func downloadAndCachePostImage(postId: String, completion: @escaping (Data?) -> Void) {
        downloadPostImage(postId: postId) { imageData in
            completion(imageData)
        }
    }
    
    func fetchPosts(completion: @escaping (Result<[Post], Error>) -> Void) {
        db.collection("posts")
            .order(by: "postDate", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                var posts: [Post] = []
                let group = DispatchGroup()
                
                for document in documents {
                    group.enter()
                    let data = document.data()
                    
                    let postId = data["postId"] as? String ?? ""
                    let title = data["title"] as? String ?? ""
                    let content = data["content"] as? String ?? ""
                    let likes = data["likes"] as? Int ?? 0
                    let authorId = data["authorId"] as? String ?? ""
                    let imageURL = data["imageURL"] as? String // 获取图片URL
                    let likedByUserIds = data["likedByUserIds"] as? [String] ?? []
                    
                    // 首先获取作者信息
                    self.getUserData(userId: authorId) { result in
                        switch result {
                        case .success(let author):
                            let post = Post(
                                postId: postId,
                                title: title,
                                content: content,
                                postImage: nil, // 初始化为nil，稍后下载
                                author: author
                            )
                            post.likes = likes
                            
                            if let timestamp = data["postDate"] as? Timestamp {
                                post.postDate = timestamp.dateValue()
                            }
                            
                            // 新增：重建 likedByUsers
                            for userId in likedByUserIds {
                                self.getUserData(userId: userId) { userResult in
                                    if case .success(let likedUser) = userResult {
                                        post.likedByUsers.append(likedUser)
                                    }
                                }
                            }
                            
                            // 如果有图片URL，下载图片
                            if let imageURL = imageURL {
                                self.downloadPostImage(postId: postId) { imageData in
                                    post.postImage = imageData
                                    
                                    // 获取评论
                                    self.fetchCommentsForPost(postId: postId) { comments in
                                        for comment in comments {
                                            comment.post = post
                                            if let commentAuthorId = comment.author?.userId {
                                                self.getUserData(userId: commentAuthorId) { result in
                                                    if case .success(let commentAuthor) = result {
                                                        comment.author = commentAuthor
                                                    }
                                                }
                                            }
                                        }
                                        post.comments = comments
                                        posts.append(post)
                                        group.leave()
                                    }
                                }
                            } else {
                                // 没有图片，直接处理评论
                                self.fetchCommentsForPost(postId: postId) { comments in
                                    for comment in comments {
                                        comment.post = post
                                        if let commentAuthorId = comment.author?.userId {
                                            self.getUserData(userId: commentAuthorId) { result in
                                                if case .success(let commentAuthor) = result {
                                                    comment.author = commentAuthor
                                                }
                                            }
                                        }
                                    }
                                    post.comments = comments
                                    posts.append(post)
                                    group.leave()
                                }
                            }
                            
                        case .failure(let error):
                            print("Error fetching author: \(error)")
                            group.leave()
                        }
                    }
                }
                
                group.notify(queue: .main) {
                    posts.sort { $0.postDate > $1.postDate }
                    completion(.success(posts))
                }
            }
    }

    // 新增方法：从 Firestore 获取用户数据
    private func getUserDataFromFirestore(userId: String, completion: @escaping (User?) -> Void) {
        db.collection("users").document(userId).getDocument { document, error in
            guard let document = document, document.exists,
                  let data = document.data() else {
                completion(nil)
                return
            }
            
            let username = data["username"] as? String ?? ""
            let email = data["email"] as? String ?? ""
            let gender = data["gender"] as? String ?? "Unknown"
            
            let user = User(
                userId: userId,
                username: username,
                password: "",
                email: email,
                gender: gender
            )
            
            completion(user)
        }
    }
    
    // 更新帖子点赞数
    func updatePostLikeStatus(postId: String, userId: String, isLiking: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        let postRef = db.collection("posts").document(postId)
        
        if isLiking {
            postRef.updateData([
                "likes": FieldValue.increment(Int64(1)),
                "likedByUserIds": FieldValue.arrayUnion([userId])
            ]) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } else {
            postRef.updateData([
                "likes": FieldValue.increment(Int64(-1)),
                "likedByUserIds": FieldValue.arrayRemove([userId])
            ]) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    
    // 删除帖子
    func deletePost(postId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        // 先删除帖子的所有评论
        db.collection("comments")
            .whereField("postId", isEqualTo: postId)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                let batch = self.db.batch()
                snapshot?.documents.forEach { document in
                    batch.deleteDocument(document.reference)
                }
                
                // 然后删除帖子
                let postRef = self.db.collection("posts").document(postId)
                batch.deleteDocument(postRef)
                
                batch.commit { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
            }
    }
}

// MARK: - Comment 相关方法
extension FirebaseService {
    
    // 添加评论
    func addComment(postId: String, content: String, author: User, completion: @escaping (Result<PostComment, Error>) -> Void) {
        let commentId = UUID().uuidString
        let commentData: [String: Any] = [
            "commentId": commentId,
            "postId": postId,
            "content": content,
            "likes": 0,
            "commentDate": Timestamp(date: Date()),
            "authorId": author.userId,
            "authorUsername": author.username
        ]
        
        db.collection("comments").document(commentId).setData(commentData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                let comment = PostComment(
                    commentId: commentId,
                    content: content,
                    author: author
                )
                completion(.success(comment))
            }
        }
    }
    
    // 获取帖子的所有评论
    func fetchCommentsForPost(postId: String, completion: @escaping ([PostComment]) -> Void) {
        db.collection("comments")
            .whereField("postId", isEqualTo: postId)
            .order(by: "commentDate", descending: false)
            .getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                var comments: [PostComment] = []
                
                for document in documents {
                    let data = document.data()
                    let commentId = data["commentId"] as? String ?? ""
                    let content = data["content"] as? String ?? ""
                    let likes = data["likes"] as? Int ?? 0
                    let authorId = data["authorId"] as? String ?? ""
                    let authorUsername = data["authorUsername"] as? String ?? ""
                    
                    // 创建完整的用户对象
                    let author = User(
                        userId: authorId,
                        username: authorUsername,
                        password: "",
                        email: "", // 如果需要可以从 Firestore 获取
                        gender: "Unknown"
                    )
                    
                    let comment = PostComment(
                        commentId: commentId,
                        content: content,
                        author: author
                    )
                    comment.likes = likes
                    
                    if let timestamp = data["commentDate"] as? Timestamp {
                        comment.commentDate = timestamp.dateValue()
                    }
                    
                    comments.append(comment)
                }
                
                completion(comments)
            }
    }
    
    // 更新评论点赞数
    func updateCommentLikes(commentId: String, likes: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("comments").document(commentId).updateData([
            "likes": likes
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // 删除评论
    func deleteComment(commentId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("comments").document(commentId).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    
    // 同步版本（供 PostDetailView 使用）
    func fetchCommentsForPostSync(postId: String) async throws -> [PostComment] {
        try await withCheckedThrowingContinuation { continuation in
            fetchCommentsForPost(postId: postId) { comments in
                continuation.resume(returning: comments)
            }
        }
    }
}

// 在 FirebaseService.swift 中添加这个方法
extension FirebaseService {
    
    // 获取用户统计数据
    func fetchUserStats(userId: String, completion: @escaping (UserStats) -> Void) {
        var postCount = 0
        var commentCount = 0
        var totalLikes = 0
        
        let group = DispatchGroup()
        
        // 获取用户的帖子数量和总点赞数
        group.enter()
        db.collection("posts")
            .whereField("authorId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                if let documents = snapshot?.documents {
                    postCount = documents.count
                    totalLikes = documents.reduce(0) { sum, document in
                        let likes = document.data()["likes"] as? Int ?? 0
                        return sum + likes
                    }
                }
                group.leave()
            }
        
        // 获取用户的评论数量
        group.enter()
        db.collection("comments")
            .whereField("authorId", isEqualTo: userId)
            .getDocuments { snapshot, error in
                if let documents = snapshot?.documents {
                    commentCount = documents.count
                }
                group.leave()
            }
        
        group.notify(queue: .main) {
            let stats = UserStats(
                postCount: postCount,
                commentCount: commentCount,
                totalLikes: totalLikes
            )
            completion(stats)
        }
    }
}


// 在 FirebaseService.swift 中添加这些扩展方法

// MARK: - Firebase Storage 头像管理
extension FirebaseService {
    
    // 上传用户头像到 Firebase Storage
    func uploadUserAvatarToStorage(userId: String, imageData: Data, completion: @escaping (Result<URL, Error>) -> Void) {
        // 创建存储引用
        let storageRef = Storage.storage().reference()
        let avatarRef = storageRef.child("avatars/\(userId).jpg")
        
        // 创建图片元数据
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        print("🔄 Starting avatar upload to Firebase Storage for user: \(userId)")
        print("📊 Image data size: \(imageData.count) bytes")
        
        // 上传到 Storage
        avatarRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                print("❌ Avatar upload to Storage failed: \(error)")
                completion(.failure(error))
                return
            }
            
            print("✅ Avatar successfully uploaded to Storage")
            
            // 获取下载 URL
            avatarRef.downloadURL { url, error in
                if let error = error {
                    print("❌ Failed to get download URL: \(error)")
                    completion(.failure(error))
                    return
                }
                
                guard let downloadURL = url else {
                    completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])))
                    return
                }
                
                print("✅ Successfully got download URL: \(downloadURL.absoluteString)")
                
                // 更新 Firestore 中的头像 URL
                self.updateUserAvatarURL(userId: userId, avatarURL: downloadURL.absoluteString) { result in
                    switch result {
                    case .success:
                        completion(.success(downloadURL))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    // 从 Firebase Storage 下载用户头像
    func downloadUserAvatarFromStorage(userId: String, completion: @escaping (Data?) -> Void) {
        let storageRef = Storage.storage().reference()
        let avatarRef = storageRef.child("avatars/\(userId).jpg")
        
        // 设置最大下载大小（例如 10MB）
        let maxSize: Int64 = 10 * 1024 * 1024
        
        avatarRef.getData(maxSize: maxSize) { data, error in
            if let error = error {
                print("❌ Failed to download avatar from Storage: \(error)")
                completion(nil)
                return
            }
            
            if let data = data {
                print("✅ Successfully downloaded avatar from Storage, size: \(data.count) bytes")
                completion(data)
            } else {
                print("ℹ️ No avatar data found in Storage for user: \(userId)")
                completion(nil)
            }
        }
    }
    
    // 删除 Firebase Storage 中的用户头像
    func deleteUserAvatarFromStorage(userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let storageRef = Storage.storage().reference()
        let avatarRef = storageRef.child("avatars/\(userId).jpg")
        
        avatarRef.delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                // 同时清除 Firestore 中的头像 URL
                self.db.collection("users").document(userId).updateData([
                    "avatarURL": "",
                    "lastUpdated": Timestamp(date: Date())
                ]) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
            }
        }
    }
    
    // 更新用户头像 URL 到 Firestore（私有方法）
    private func updateUserAvatarURL(userId: String, avatarURL: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("users").document(userId).updateData([
            "avatarURL": avatarURL,
            "lastUpdated": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                print("❌ Failed to update avatar URL in Firestore: \(error)")
                completion(.failure(error))
            } else {
                print("✅ Successfully updated avatar URL in Firestore")
                completion(.success(()))
            }
        }
    }
    
    // 获取用户头像 URL（从 Firestore）
    func getUserAvatarURL(userId: String, completion: @escaping (String?) -> Void) {
        db.collection("users").document(userId).getDocument { document, error in
            guard let document = document, document.exists,
                  let data = document.data() else {
                completion(nil)
                return
            }
            
            let avatarURL = data["avatarURL"] as? String
            completion(avatarURL)
        }
    }
}




// MARK: - Post Image Storage Methods
extension FirebaseService {
    
    // 上传帖子图片到 Firebase Storage
    func uploadPostImage(postId: String, imageData: Data, completion: @escaping (Result<String, Error>) -> Void) {
        let storageRef = Storage.storage().reference()
        let imageRef = storageRef.child("post_images/\(postId).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        print("🔄 Starting post image upload to Firebase Storage for post: \(postId)")
        print("📊 Image data size: \(imageData.count) bytes")
        
        imageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                print("❌ Post image upload to Storage failed: \(error)")
                completion(.failure(error))
                return
            }
            
            print("✅ Post image successfully uploaded to Storage")
            
            // 获取下载 URL
            imageRef.downloadURL { url, error in
                if let error = error {
                    print("❌ Failed to get download URL for post image: \(error)")
                    completion(.failure(error))
                    return
                }
                
                guard let downloadURL = url else {
                    completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])))
                    return
                }
                
                print("✅ Successfully got post image download URL: \(downloadURL.absoluteString)")
                completion(.success(downloadURL.absoluteString))
            }
        }
    }
    
    // 从 Firebase Storage 下载帖子图片
    func downloadPostImage(postId: String, completion: @escaping (Data?) -> Void) {
        let storageRef = Storage.storage().reference()
        let imageRef = storageRef.child("post_images/\(postId).jpg")
        
        let maxSize: Int64 = 10 * 1024 * 1024 // 10MB
        
        imageRef.getData(maxSize: maxSize) { data, error in
            if let error = error {
                print("❌ Failed to download post image from Storage: \(error)")
                completion(nil)
                return
            }
            
            if let data = data {
                print("✅ Successfully downloaded post image from Storage, size: \(data.count) bytes")
                completion(data)
            } else {
                print("ℹ️ No post image data found in Storage for post: \(postId)")
                completion(nil)
            }
        }
    }
    
    // 删除帖子图片
    func deletePostImage(postId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let storageRef = Storage.storage().reference()
        let imageRef = storageRef.child("post_images/\(postId).jpg")
        
        imageRef.delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    
    // 在 FirebaseService.swift 的 extension 中添加
    func getPostData(postId: String) async throws -> [String: Any]? {
        let document = try await db.collection("posts").document(postId).getDocument()
        return document.data()
    }
}




// MARK: - 课程相关方法
extension FirebaseService {
    
    // 修改后的 addCourseToUser 方法
//    func addCourseToUser(userId: String, courseId: String, completion: @escaping (Result<Void, Error>) -> Void) {
//        let userRef = db.collection("users").document(userId)
//        
//        // 先检查文档是否存在以及是否有 enrolledCourseIds 字段
//        userRef.getDocument { snapshot, error in
//            if let error = error {
//                completion(.failure(error))
//                return
//            }
//            
//            if let snapshot = snapshot, snapshot.exists {
//                // 文档存在，检查是否有 enrolledCourseIds 字段
//                if let existingCourseIds = snapshot.data()?["enrolledCourseIds"] as? [String] {
//                    // 字段存在，使用 arrayUnion
//                    userRef.updateData([
//                        "enrolledCourseIds": FieldValue.arrayUnion([courseId])
//                    ]) { error in
//                        if let error = error {
//                            completion(.failure(error))
//                        } else {
//                            completion(.success(()))
//                        }
//                    }
//                } else {
//                    // 字段不存在，直接设置数组
//                    userRef.updateData([
//                        "enrolledCourseIds": [courseId]
//                    ]) { error in
//                        if let error = error {
//                            completion(.failure(error))
//                        } else {
//                            completion(.success(()))
//                        }
//                    }
//                }
//            } else {
//                // 文档不存在（理论上不应该发生）
//                completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User document not found"])))
//            }
//        }
//    }
    
    
    func addCourseToUser(userId: String, courseId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let userRef = db.collection("users").document(userId)
        
        print("🔄 开始更新用户课程: userId=\(userId), courseId=\(courseId)")
        
        // 先检查文档是否存在以及是否有 enrolledCourseIds 字段
        userRef.getDocument { snapshot, error in
            if let error = error {
                print("❌ 获取用户文档失败: \(error)")
                completion(.failure(error))
                return
            }
            
            if let snapshot = snapshot, snapshot.exists {
                print("✅ 用户文档存在")
                
                // 文档存在，检查是否有 enrolledCourseIds 字段
                if let existingCourseIds = snapshot.data()?["enrolledCourseIds"] as? [String] {
                    print("ℹ️ 已有 enrolledCourseIds: \(existingCourseIds)")
                    // 字段存在，使用 arrayUnion
                    userRef.updateData([
                        "enrolledCourseIds": FieldValue.arrayUnion([courseId])
                    ]) { error in
                        if let error = error {
                            print("❌ 更新 enrolledCourseIds 失败: \(error)")
                            completion(.failure(error))
                        } else {
                            print("✅ 成功添加课程到 enrolledCourseIds")
                            completion(.success(()))
                        }
                    }
                } else {
                    print("ℹ️ enrolledCourseIds 字段不存在，创建新数组")
                    // 字段不存在，直接设置数组
                    userRef.updateData([
                        "enrolledCourseIds": [courseId]
                    ]) { error in
                        if let error = error {
                            print("❌ 创建 enrolledCourseIds 失败: \(error)")
                            completion(.failure(error))
                        } else {
                            print("✅ 成功创建 enrolledCourseIds")
                            completion(.success(()))
                        }
                    }
                }
            } else {
                print("❌ 用户文档不存在")
                // 文档不存在（理论上不应该发生）
                completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User document not found"])))
            }
        }
    }
    
    // （可选）获取用户已选课程 ID 列表
    func fetchEnrolledCourseIds(for userId: String, completion: @escaping (Result<[String], Error>) -> Void) {
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            let courseIds = snapshot?.data()?["enrolledCourseIds"] as? [String] ?? []
            completion(.success(courseIds))
        }
    }
}



// MARK: - 用户课程同步核心方法（必须加！）
extension FirebaseService {
    
    /// 登录后调用：获取用户资料 + 同步已选课程到本地 SwiftData
    /// 登录后调用：获取用户资料 + 同步已选课程到本地 SwiftData
    func getUserDataAndSyncCourses(userId: String,
                                   modelContext: ModelContext,
                                   completion: @escaping (Result<User, Error>) -> Void) {
        
        let userRef = db.collection("users").document(userId)
        
        userRef.getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = snapshot?.data(), snapshot?.exists == true else {
                completion(.failure(NSError(domain: "Firebase", code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "用户资料不存在"])))
                return
            }
            
            // 1. 创建本地 User 对象
            let username = data["username"] as? String ?? "Unknown"
            let email = data["email"] as? String ?? ""
            let gender = data["gender"] as? String ?? "Male"
            let avatarURL = data["avatarURL"] as? String ?? ""
            let enrolledCourseIds = data["enrolledCourseIds"] as? [String] ?? [] // 新增这行！
            
            let user = User(
                userId: userId,
                username: username,
                password: "",
                email: email,
                gender: gender,
                enrolledCourseIds: enrolledCourseIds  // 新增这行！
            )
            modelContext.insert(user)
            
            // 2. 读取 Firebase 中的 enrolledCourseIds (已经在上面的初始化中设置了)
            print("ℹ️ 从 Firebase 加载的 enrolledCourseIds: \(enrolledCourseIds)")
            
            // 3. 自动恢复完整课程到 SwiftData（只添加还不存在的）
            let allSampleCourses = createSampleCourses()
            
            for courseId in enrolledCourseIds {
                // 如果本地还没这门课，才深拷贝一份加进去
                if user.courses.contains(where: { $0.courseId == courseId }) {
                    continue
                }
                
                if let template = allSampleCourses.first(where: { $0.courseId == courseId }) {
                    let copiedCourse = self.deepCopyCourse(template)
                    user.courses.append(copiedCourse)
                    modelContext.insert(copiedCourse)
                }
            }
            
            // 保存到本地 SwiftData
            do {
                try modelContext.save()
                print("已成功同步 \(enrolledCourseIds.count) 门课程到本地")
            } catch {
                print("同步课程到 SwiftData 失败：\(error)")
            }
            
            completion(.success(user))
        }
    }
    
    /// 工具方法：深拷贝课程（避免所有用户共享同一实例）
    private func deepCopyCourse(_ course: Course) -> Course {
        let newCourse = Course(
            courseId: course.courseId,
            courseName: course.courseName,
            professor: course.professor,
            courseCode: course.courseCode,
            credits: course.credits,
            courseDescription: course.courseDescription
        )
        
        // 复制上课时间
        for ct in course.classTimes {
            let newCT = ClassTime(
                dayOfWeek: ct.dayOfWeek,
                startTime: ct.startTime,
                endTime: ct.endTime,
                location: ct.location,
                course: newCourse
            )
            newCourse.classTimes.append(newCT)
        }
        
        // 复制作业
        for hw in course.homeworkList {
            let newHW = Homework(
                homeworkId: hw.homeworkId,
                title: hw.title,
                dueDate: hw.dueDate,
                course: newCourse
            )
            newCourse.homeworkList.append(newHW)
        }
        
        return newCourse
    }
    
    
    
    // 检查用户是否已选某门课
    func checkIfUserHasCourse(userId: String, courseId: String, completion: @escaping (Bool) -> Void) {
        fetchEnrolledCourseIds(for: userId) { result in
            switch result {
            case .success(let courseIds):
                completion(courseIds.contains(courseId))
            case .failure:
                completion(false)
            }
        }
    }
}
