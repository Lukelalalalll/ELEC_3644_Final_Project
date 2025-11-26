import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import SwiftData

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    
    let db = Firestore.firestore()
    
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
            
            let userData: [String: Any] = [
                "userId": user.uid,
                "username": username,
                "email": email,
                "gender": gender,
                "avatarURL": "",
                "joinDate": Timestamp(date: Date()),
                "enrolledCourseIds": []
            ]
            
            self.db.collection("users").document(user.uid).setData(userData) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    let localUser = User(
                        userId: user.uid,
                        username: username,
                        password: "",
                        email: email,
                        gender: gender,
                        enrolledCourseIds: []
                    )
                    completion(.success(localUser))
                }
            }
        }
    }
    
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
            
            self.getUserData(userId: user.uid) { result in
                completion(result)
            }
        }
    }
    
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
            let avatarURL = data["avatarURL"] as? String ?? ""
            let enrolledCourseIds = data["enrolledCourseIds"] as? [String] ?? []
            let user = User(
                userId: userId,
                username: username,
                password: "",
                email: email,
                gender: gender,
                enrolledCourseIds: enrolledCourseIds
            )
            
            completion(.success(user))
        }
    }
    
    func checkUsernameUnique(_ username: String, completion: @escaping (Bool) -> Void) {
        db.collection("users")
            .whereField("username", isEqualTo: username)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(false)
                    return
                }
                
                completion(snapshot?.documents.isEmpty ?? true)
            }
    }
    
    func logout() {
        do {
            try Auth.auth().signOut()
        } catch {
        }
    }
    
    func getCurrentUser(completion: @escaping (User?) -> Void) {
        if let currentUser = Auth.auth().currentUser {
            self.getUserData(userId: currentUser.uid) { result in
                switch result {
                case .success(let user):
                    completion(user)
                case .failure:
                    completion(nil)
                }
            }
        } else {
            completion(nil)
        }
    }
}

extension FirebaseService {
    
    func publishPost(title: String, content: String, imageData: Data? = nil, author: User, completion: @escaping (Result<Post, Error>) -> Void) {
        let postId = UUID().uuidString
        
        if let imageData = imageData {
            uploadPostImage(postId: postId, imageData: imageData) { [weak self] result in
                switch result {
                case .success(let imageURL):
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
        
        if let imageURL = imageURL {
            postData["imageURL"] = imageURL
        }
        
        db.collection("posts").document(postId).setData(postData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                let post = Post(
                    postId: postId,
                    title: title,
                    content: content,
                    postImage: nil,
                    author: author
                )
                
                if let imageURL = imageURL {
                    self.downloadAndCachePostImage(postId: postId) { imageData in
                        post.postImage = imageData
                    }
                }
                
                completion(.success(post))
            }
        }
    }

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
                    let imageURL = data["imageURL"] as? String
                    let likedByUserIds = data["likedByUserIds"] as? [String] ?? []
                    
                    self.getUserData(userId: authorId) { result in
                        switch result {
                        case .success(let author):
                            let post = Post(
                                postId: postId,
                                title: title,
                                content: content,
                                postImage: nil,
                                author: author
                            )
                            post.likes = likes
                            
                            if let timestamp = data["postDate"] as? Timestamp {
                                post.postDate = timestamp.dateValue()
                            }
                            
                            for userId in likedByUserIds {
                                self.getUserData(userId: userId) { userResult in
                                    if case .success(let likedUser) = userResult {
                                        post.likedByUsers.append(likedUser)
                                    }
                                }
                            }
                            
                            if let imageURL = imageURL {
                                self.downloadPostImage(postId: postId) { imageData in
                                    post.postImage = imageData
                                    
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
                            
                        case .failure:
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
    
    func deletePost(postId: String, completion: @escaping (Result<Void, Error>) -> Void) {
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

extension FirebaseService {
    
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
                    
                    let author = User(
                        userId: authorId,
                        username: authorUsername,
                        password: "",
                        email: "",
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
    
    func deleteComment(commentId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("comments").document(commentId).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func fetchCommentsForPostSync(postId: String) async throws -> [PostComment] {
        try await withCheckedThrowingContinuation { continuation in
            fetchCommentsForPost(postId: postId) { comments in
                continuation.resume(returning: comments)
            }
        }
    }
}

extension FirebaseService {
    
    func fetchUserStats(userId: String, completion: @escaping (UserStats) -> Void) {
        var postCount = 0
        var commentCount = 0
        var totalLikes = 0
        
        let group = DispatchGroup()
        
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

extension FirebaseService {
    
    func uploadUserAvatarToStorage(userId: String, imageData: Data, completion: @escaping (Result<URL, Error>) -> Void) {
        let storageRef = Storage.storage().reference()
        let avatarRef = storageRef.child("avatars/\(userId).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        avatarRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            avatarRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let downloadURL = url else {
                    completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])))
                    return
                }
                
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
    
    func downloadUserAvatarFromStorage(userId: String, completion: @escaping (Data?) -> Void) {
        let storageRef = Storage.storage().reference()
        let avatarRef = storageRef.child("avatars/\(userId).jpg")
        
        let maxSize: Int64 = 10 * 1024 * 1024
        
        avatarRef.getData(maxSize: maxSize) { data, error in
            if let error = error {
                completion(nil)
                return
            }
            
            if let data = data {
                completion(data)
            } else {
                completion(nil)
            }
        }
    }
    
    func deleteUserAvatarFromStorage(userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let storageRef = Storage.storage().reference()
        let avatarRef = storageRef.child("avatars/\(userId).jpg")
        
        avatarRef.delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
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
    
    private func updateUserAvatarURL(userId: String, avatarURL: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("users").document(userId).updateData([
            "avatarURL": avatarURL,
            "lastUpdated": Timestamp(date: Date())
        ]) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
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

extension FirebaseService {
    
    func uploadPostImage(postId: String, imageData: Data, completion: @escaping (Result<String, Error>) -> Void) {
        let storageRef = Storage.storage().reference()
        let imageRef = storageRef.child("post_images/\(postId).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        imageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            imageRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let downloadURL = url else {
                    completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])))
                    return
                }
                
                completion(.success(downloadURL.absoluteString))
            }
        }
    }
    
    func downloadPostImage(postId: String, completion: @escaping (Data?) -> Void) {
        let storageRef = Storage.storage().reference()
        let imageRef = storageRef.child("post_images/\(postId).jpg")
        
        let maxSize: Int64 = 10 * 1024 * 1024
        
        imageRef.getData(maxSize: maxSize) { data, error in
            if let error = error {
                completion(nil)
                return
            }
            
            if let data = data {
                completion(data)
            } else {
                completion(nil)
            }
        }
    }
    
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
    
    func getPostData(postId: String) async throws -> [String: Any]? {
        let document = try await db.collection("posts").document(postId).getDocument()
        return document.data()
    }
}

extension FirebaseService {
    
    func addCourseToUser(userId: String, courseId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let userRef = db.collection("users").document(userId)
        
        userRef.getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let snapshot = snapshot, snapshot.exists {
                if let existingCourseIds = snapshot.data()?["enrolledCourseIds"] as? [String] {
                    userRef.updateData([
                        "enrolledCourseIds": FieldValue.arrayUnion([courseId])
                    ]) { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            completion(.success(()))
                        }
                    }
                } else {
                    userRef.updateData([
                        "enrolledCourseIds": [courseId]
                    ]) { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            completion(.success(()))
                        }
                    }
                }
            } else {
                completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User document not found"])))
            }
        }
    }
    
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

extension FirebaseService {

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
                    userInfo: [NSLocalizedDescriptionKey: "User data not found"])))
                return
            }
            
            let username = data["username"] as? String ?? "Unknown"
            let email = data["email"] as? String ?? ""
            let gender = data["gender"] as? String ?? "Male"
            let avatarURL = data["avatarURL"] as? String ?? ""
            let enrolledCourseIds = data["enrolledCourseIds"] as? [String] ?? []
            
            let user = User(
                userId: userId,
                username: username,
                password: "",
                email: email,
                gender: gender,
                enrolledCourseIds: enrolledCourseIds
            )
            modelContext.insert(user)
                        
            let allSampleCourses = createSampleCourses()
            
            for courseId in enrolledCourseIds {
                if user.courses.contains(where: { $0.courseId == courseId }) {
                    continue
                }
                
                if let template = allSampleCourses.first(where: { $0.courseId == courseId }) {
                    let copiedCourse = self.deepCopyCourse(template)
                    user.courses.append(copiedCourse)
                    modelContext.insert(copiedCourse)
                }
            }
            
            do {
                try modelContext.save()
            } catch {
            }
            
            completion(.success(user))
        }
    }
    
    private func deepCopyCourse(_ course: Course) -> Course {
        let newCourse = Course(
            courseId: course.courseId,
            courseName: course.courseName,
            professor: course.professor,
            courseCode: course.courseCode,
            credits: course.credits,
            courseDescription: course.courseDescription
        )
        
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

extension FirebaseService {
    
    func addCourseComment(courseId: String, content: String, rating: Int, author: User, completion: @escaping (Result<CourseComment, Error>) -> Void) {
        let commentId = UUID().uuidString
        let commentData: [String: Any] = [
            "commentId": commentId,
            "courseId": courseId,
            "content": content,
            "rating": rating,
            "commentDate": Timestamp(date: Date()),
            "authorId": author.userId,
            "authorUsername": author.username
        ]
        
        db.collection("courseComments").document(commentId).setData(commentData) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                let comment = CourseComment(
                    commentId: commentId,
                    content: content,
                    rating: rating,
                    author: author
                )
                completion(.success(comment))
            }
        }
    }
    
    func fetchCourseComments(courseId: String, completion: @escaping (Result<[CourseComment], Error>) -> Void) {
        db.collection("courseComments")
            .whereField("courseId", isEqualTo: courseId)
            .order(by: "commentDate", descending: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                var comments: [CourseComment] = []
                let group = DispatchGroup()
                
                for document in documents {
                    let data = document.data()
                    let commentId = data["commentId"] as? String ?? ""
                    let content = data["content"] as? String ?? ""
                    let rating = data["rating"] as? Int ?? 5
                    let authorId = data["authorId"] as? String ?? ""
                    let authorUsername = data["authorUsername"] as? String ?? ""
                    
                    let comment = CourseComment(
                        commentId: commentId,
                        content: content,
                        rating: rating
                    )
                    
                    if let timestamp = data["commentDate"] as? Timestamp {
                        comment.commentDate = timestamp.dateValue()
                    }
                    
                    group.enter()
                    self.getUserData(userId: authorId) { result in
                        switch result {
                        case .success(let author):
                            comment.author = author
                        case .failure:
                            let fallbackAuthor = User(
                                userId: authorId,
                                username: authorUsername,
                                password: "",
                                email: "",
                                gender: "Unknown"
                            )
                            comment.author = fallbackAuthor
                        }
                        group.leave()
                    }
                    
                    comments.append(comment)
                }
                
                group.notify(queue: .main) {
                    completion(.success(comments))
                }
            }
    }
    
    func deleteCourseComment(commentId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        db.collection("courseComments").document(commentId).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func fetchCourseCommentsSync(courseId: String) async throws -> [CourseComment] {
        try await withCheckedThrowingContinuation { continuation in
            fetchCourseComments(courseId: courseId) { result in
                switch result {
                case .success(let comments):
                    continuation.resume(returning: comments)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
