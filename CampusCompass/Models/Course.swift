import SwiftData
import Foundation

@Model
class Course {
    var courseId: String
    var courseName: String
    var professor: String
    var courseCode: String
    var credits: Int
    var courseDescription: String
    
    @Relationship(deleteRule: .cascade)
    var classTimes: [ClassTime] = []
    
    @Relationship(deleteRule: .cascade)
    var homeworkList: [Homework] = []
    
    @Relationship(deleteRule: .nullify)
    var students: [User] = []
    
    @Relationship(deleteRule: .cascade)
    var comments: [CourseComment] = []
    
    init(courseId: String, courseName: String, professor: String, courseCode: String, credits: Int = 3, courseDescription: String = "") {
        self.courseId = courseId
        self.courseName = courseName
        self.professor = professor
        self.courseCode = courseCode
        self.credits = credits
        self.courseDescription = courseDescription
    }
    
    func addClassTime(dayOfWeek: Int, startTime: Date, endTime: Date, location: String = "") {
        let classTime = ClassTime(dayOfWeek: dayOfWeek, startTime: startTime, endTime: endTime, location: location)
        classTimes.append(classTime)
    }
    
    func addHomework(homeworkId: String, title: String, dueDate: Date, priority: Int = 3) {
        let homework = Homework(homeworkId: homeworkId, title: title, dueDate: dueDate)
        homeworkList.append(homework)
    }
    
    func averageRating() -> Double {
        guard !comments.isEmpty else { return 0.0 }
        let total = comments.reduce(0) { $0 + Double($1.rating) }
        return total / Double(comments.count)
    }
}

