//
//  ClassTime.swift
//  ELEC_3644_Final_Project
//
//  Created by cccakkke on 2025/11/21.
//

import SwiftData
import Foundation

@Model
class ClassTime {
    var dayOfWeek: Int // 1-7 表示周一到周日
    var startTime: Date // 开始时间
    var endTime: Date // 结束时间
    var location: String // 上课地点
    
    // 关系 - 所属的课程
    var course: Course?
    
    init(dayOfWeek: Int, startTime: Date, endTime: Date, location: String = "", course: Course? = nil) {
        self.dayOfWeek = dayOfWeek
        self.startTime = startTime
        self.endTime = endTime
        self.location = location
        self.course = course
    }
    
    // 便捷方法：获取时间字符串
    func timeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(dayOfWeekString()) \(formatter.string(from: startTime))-\(formatter.string(from: endTime))"
    }
    
    // 便捷方法：获取星期几字符串
    func dayOfWeekString() -> String {
        let days = ["", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
        return dayOfWeek >= 1 && dayOfWeek <= 7 ? days[dayOfWeek] : "Unknown"
    }
    
    // 便捷方法：获取简化的星期几字符串
    func shortDayString() -> String {
        let days = ["", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return dayOfWeek >= 1 && dayOfWeek <= 7 ? days[dayOfWeek] : "Unknown"
    }
}
