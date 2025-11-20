//
//  PostModel.swift
//  ELEC_3644_Final_Project
//
//  Created by cccakkke on 2025/11/21.
//

import SwiftData
import Foundation

@Model
class Post {
    var postId: String
    var title: String
    var content: String
    var postImage: Data? // 帖子图片内容
    var likes: Int
    var postDate: Date
    
    // 关系 - 帖子的作者
    var author: User?
    
    // 关系 - 帖子的评论
    @Relationship(deleteRule: .cascade)
    var comments: [PostComment] = []
    
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
