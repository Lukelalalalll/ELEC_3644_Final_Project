// Course.swift
import Foundation
import SwiftData

@Model
final class Course {
    var courseId: String
    var courseName: String
    var professor: String
    var courseCode: String
    var credits: Int
    var courseDescription: String?
    var classTimes: [ClassTime] = []
    // 添加作业关联
    var homeworks: [Homework] = []  // 新增这一行
    
    init(courseId: String, courseName: String, professor: String, courseCode: String, credits: Int, courseDescription: String? = nil) {
        self.courseId = courseId
        self.courseName = courseName
        self.professor = professor
        self.courseCode = courseCode
        self.credits = credits
        self.courseDescription = courseDescription
    }
}
