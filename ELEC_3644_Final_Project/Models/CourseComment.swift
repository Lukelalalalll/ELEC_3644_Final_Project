//
//  CourseCommentModel.swift
//  ELEC_3644_Final_Project
//
//  Created by cccakkke on 2025/11/21.
//

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
    var commentDate: Date
    var rating: Int // 添加评分字段
    
    var author: User?
    var course: Course?
    
    // Firebase 同步字段
    var authorId: String?
    var courseId: String?
    
    init(commentId: String, content: String, rating: Int = 5, author: User? = nil, course: Course? = nil) {
        self.commentId = commentId
        self.content = content
        self.rating = rating
        self.commentDate = Date()
        self.author = author
        self.course = course
        self.authorId = author?.userId
        self.courseId = course?.courseId
    }
}
