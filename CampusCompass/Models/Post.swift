import SwiftData
import Foundation

@Model
class Post {
    var postId: String
    var title: String
    var content: String
    var postImage: Data?
    var likes: Int
    var postDate: Date
    
    var author: User?
    
    @Relationship(deleteRule: .cascade)
    var comments: [PostComment] = []
    
    @Relationship(deleteRule: .nullify)
    var likedByUsers: [User] = []
    
    init(postId: String, title: String, content: String, postImage: Data? = nil, author: User? = nil) {
        self.postId = postId
        self.title = title
        self.content = content
        self.postImage = postImage
        self.likes = 0
        self.postDate = Date()
        self.author = author
    }
}

extension Post {
    func like(by user: User) {
        if !likedByUsers.contains(where: { $0.userId == user.userId }) {
            likedByUsers.append(user)
            likes += 1
        }
    }

    func unlike(by user: User) {
        likedByUsers.removeAll { $0.userId == user.userId }
        likes = max(0, likes - 1)
    }

    func isLiked(by user: User) -> Bool {
        return likedByUsers.contains { $0.userId == user.userId }
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: postDate)
    }
    
    var commentCount: Int {
        return comments.count
    }
}


extension Post {
    static var mockPosts: [Post] {
        return [
            Post(postId: "1", title: "Campus Navigation Tips", content: "Found a great campus navigation tip today, sharing with everyone! The shortest path from the library to the engineering building is actually through the small garden, which can save 5 minutes."),
            Post(postId: "2", title: "Study Group Recruitment", content: "Looking for classmates to learn SwiftUI together, meeting every Wednesday evening in the group study area on the third floor of the library. Interested students are welcome to leave a message!"),
            Post(postId: "3", title: "Cafeteria New Item Recommendation", content: "The new spicy stir-fry pot in the second cafeteria is really good, affordable with generous portions. Recommend everyone to try it!")
        ]
    }
}
