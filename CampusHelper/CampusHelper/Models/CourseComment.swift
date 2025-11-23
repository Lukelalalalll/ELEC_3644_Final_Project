// CourseComment.swift
import Foundation
import SwiftData

@Model
final class CourseComment {
    var commentId: String
    var content: String
    var rating: Int
    var commentDate: Date
    var author: User? // 移除@Relationship
    var course: Course? // 移除@Relationship
    
    init(commentId: String, content: String, rating: Int, commentDate: Date = Date(), author: User? = nil, course: Course? = nil) {
        self.commentId = commentId
        self.content = content
        self.rating = rating
        self.commentDate = commentDate
        self.author = author
        self.course = course
    }
}
