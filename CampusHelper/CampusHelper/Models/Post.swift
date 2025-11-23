// Post.swift
import Foundation
import SwiftData

@Model
final class Post {
    @Attribute(.unique) var postId: String
    var title: String
    var content: String
    var postImage: Data?
    var likes: Int
    var postDate: Date
    var author: User? // 移除@Relationship
    var comments: [PostComment] = [] // 移除@Relationship
    
    init(
        postId: String = UUID().uuidString,
        title: String = "",
        content: String = "",
        postImage: Data? = nil,
        likes: Int = 0,
        postDate: Date = Date(),
        author: User? = nil
    ) {
        self.postId = postId
        self.title = title
        self.content = content
        self.postImage = postImage
        self.likes = likes
        self.postDate = postDate
        self.author = author
    }
}
