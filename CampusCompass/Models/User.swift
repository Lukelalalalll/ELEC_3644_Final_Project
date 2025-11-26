import SwiftData
import Foundation

@Model
class User {
    var userId: String
    var username: String
    var password: String
    var email: String
    var gender: String
    
    var avatar: Data?
    
    var joinDate: Date
    
    var enrolledCourseIds: [String] = []
    
    @Relationship(deleteRule: .cascade)
    var posts: [Post] = []
    
    @Relationship(deleteRule: .nullify)
    var courses: [Course] = []
    
    @Relationship(deleteRule: .cascade)
    var postComments: [PostComment] = []
    
    @Relationship(deleteRule: .cascade)
    var courseComments: [CourseComment] = []
    
    @Relationship(deleteRule: .nullify)
    var likedPosts: [Post] = []
    
    @Relationship(deleteRule: .nullify)
    var likedComments: [PostComment] = []
    
    init(userId: String,
         username: String,
         password: String = "",
         email: String,
         gender: String,
         avatar: Data? = nil,
         joinDate: Date = Date(),
         enrolledCourseIds: [String] = []) {
        self.userId = userId
        self.username = username
        self.password = password
        self.email = email
        self.gender = gender
        self.avatar = avatar
        self.joinDate = joinDate
        self.enrolledCourseIds = enrolledCourseIds
    }
    
    func daysSinceJoin() -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: joinDate, to: Date())
        return components.day ?? 0
    }
    
    func allHomeworks() -> [Homework] {
        return courses.flatMap { $0.homeworkList }
    }
    
    func dueSoonHomeworks() -> [Homework] {
        return allHomeworks().filter { $0.isDueSoon() }
    }
    
    func updateAvatar(_ imageData: Data?) {
        self.avatar = imageData
    }
    
    func hasEnrolled(courseId: String) -> Bool {
        return enrolledCourseIds.contains(courseId)
    }
}
