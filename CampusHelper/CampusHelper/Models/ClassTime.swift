// ClassTime.swift
import Foundation
import SwiftData

@Model
final class ClassTime {
    var dayOfWeek: String
    var startTime: Date
    var endTime: Date
    var location: String
    var course: Course? // 移除@Relationship
    
    init(dayOfWeek: String, startTime: Date, endTime: Date, location: String, course: Course? = nil) {
        self.dayOfWeek = dayOfWeek
        self.startTime = startTime
        self.endTime = endTime
        self.location = location
        self.course = course
    }
}
