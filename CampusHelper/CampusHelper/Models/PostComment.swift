// PostComment.swift
import Foundation
import SwiftData

@Model
final class PostComment {
    var commentId: String
    var content: String
    var commentDate: Date
    var likes: Int
    var author: User? // 移除@Relationship
    var post: Post? // 移除@Relationship
    
    init(commentId: String, content: String, commentDate: Date = Date(), likes: Int = 0, author: User? = nil, post: Post? = nil) {
        self.commentId = commentId
        self.content = content
        self.commentDate = commentDate
        self.likes = likes
        self.author = author
        self.post = post
    }
}
