// Homework.swift
import Foundation
import SwiftData

@Model
final class Homework {
    var homeworkId: String
    var title: String
    var dueDate: Date
    var isCompleted: Bool
    var course: Course?  // 已存在的课程关联
    
    init(homeworkId: String, title: String, dueDate: Date, isCompleted: Bool = false, course: Course? = nil) {
        self.homeworkId = homeworkId
        self.title = title
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.course = course
    }
}
