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

// 扩展添加计算属性用于UI显示
extension Post {
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

// 示例数据
extension Post {
    static var mockPosts: [Post] {
        return [
            Post(postId: "1", title: "校园导航技巧", content: "今天发现了一个超棒的校园导航技巧，分享给大家！从图书馆到工程楼的最短路径其实是通过小花园，能节省5分钟时间。"),
            Post(postId: "2", title: "学习小组招募", content: "寻找一起学习SwiftUI的同学，每周三晚上在图书馆三楼小组学习区见面交流。有兴趣的同学欢迎留言！"),
            Post(postId: "3", title: "食堂新品推荐", content: "二食堂新出的麻辣香锅真的很不错，价格实惠分量足，推荐大家去试试！")
        ]
    }
}
