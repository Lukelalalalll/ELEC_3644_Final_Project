import SwiftData
import Foundation

@Model
class CourseComment {
    var commentId: String
    var content: String
    var commentDate: Date
    var rating: Int
    
    var author: User?
    var course: Course?
    
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
