import SwiftData
import Foundation

@Model
class Homework {
    var homeworkId: String
    var title: String
    var dueDate: Date
    
    var course: Course?
    
    init(homeworkId: String, title: String, dueDate: Date, course: Course? = nil) {
        self.homeworkId = homeworkId
        self.title = title
        self.dueDate = dueDate
        self.course = course
    }
    
    func isDueSoon() -> Bool {
        let threeDays: TimeInterval = 3 * 24 * 60 * 60
        return dueDate.timeIntervalSinceNow <= threeDays
    }
}
