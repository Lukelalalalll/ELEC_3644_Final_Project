import SwiftData
import Foundation

@Model
class ClassTime {
    var dayOfWeek: Int
    var startTime: Date
    var endTime: Date
    var location: String
    
    var course: Course?
    
    init(dayOfWeek: Int, startTime: Date, endTime: Date, location: String = "", course: Course? = nil) {
        self.dayOfWeek = dayOfWeek
        self.startTime = startTime
        self.endTime = endTime
        self.location = location
        self.course = course
    }
    
    func timeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(dayOfWeekString()) \(formatter.string(from: startTime))-\(formatter.string(from: endTime))"
    }
    
    func dayOfWeekString() -> String {
        let days = ["", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        return dayOfWeek >= 1 && dayOfWeek <= 7 ? days[dayOfWeek] : "Unknown"
    }
    
    func shortDayString() -> String {
        let days = ["", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return dayOfWeek >= 1 && dayOfWeek <= 7 ? days[dayOfWeek] : "Unknown"
    }
}
