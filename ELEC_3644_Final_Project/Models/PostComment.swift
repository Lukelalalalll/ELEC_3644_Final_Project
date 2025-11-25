import SwiftData
import Foundation

@Model
class PostComment {
    var commentId: String
    var content: String
    var commentDate: Date
    var likes: Int
    
    var author: User?
    
    var post: Post?
    
    @Relationship(deleteRule: .nullify)
    var likedByUsers: [User] = []
    
    init(commentId: String, content: String, author: User? = nil, post: Post? = nil) {
        self.commentId = commentId
        self.content = content
        self.commentDate = Date()
        self.likes = 0
        self.author = author
        self.post = post
    }
    
    func like(by user: User) {
        if !likedByUsers.contains(where: { $0.userId == user.userId }) {
            likedByUsers.append(user)
            likes = likedByUsers.count
        }
    }
    
    func unlike(by user: User) {
        likedByUsers.removeAll { $0.userId == user.userId }
        likes = likedByUsers.count
    }
    
    func isLiked(by user: User) -> Bool {
        return likedByUsers.contains { $0.userId == user.userId }
    }
}
