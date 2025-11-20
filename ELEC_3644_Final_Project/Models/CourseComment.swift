//
//  CourseCommentModel.swift
//  ELEC_3644_Final_Project
//
//  Created by cccakkke on 2025/11/21.
//

import SwiftData
import Foundation

@Model
class CourseComment {
    var commentId: String
    var content: String
    var rating: Int // 课程评分
    var commentDate: Date
    
    // 关系 - 评论的作者
    var author: User?
    
    // 关系 - 所属的课程
    var course: Course?
    
    init(commentId: String, content: String, rating: Int = 5, author: User? = nil, course: Course? = nil) {
        self.commentId = commentId
        self.content = content
        self.rating = rating
        self.commentDate = Date()
        self.author = author
        self.course = course
    }
}
