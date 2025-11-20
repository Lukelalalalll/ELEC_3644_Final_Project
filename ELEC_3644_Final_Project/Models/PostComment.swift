//
//  PostCommentModel.swift
//  ELEC_3644_Final_Project
//
//  Created by cccakkke on 2025/11/21.
//


import SwiftData
import Foundation

@Model
class PostComment {
    var commentId: String
    var content: String
    var commentDate: Date
    var likes: Int // 新增：点赞数
    
    // 关系 - 评论的作者
    var author: User?
    
    // 关系 - 所属的帖子
    var post: Post?
    
    init(commentId: String, content: String, author: User? = nil, post: Post? = nil) {
        self.commentId = commentId
        self.content = content
        self.commentDate = Date()
        self.likes = 0
        self.author = author
        self.post = post
    }
    
    // 便捷方法：点赞
    func like() {
        likes += 1
    }
    
    // 便捷方法：取消点赞
    func unlike() {
        likes = max(0, likes - 1)
    }
}
