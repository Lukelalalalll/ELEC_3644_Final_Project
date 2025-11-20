//
//  CourseModel.swift
//  ELEC_3644_Final_Project
//
//  Created by cccakkke on 2025/11/21.
//

import SwiftData
import Foundation

@Model
class Course {
    var courseId: String
    var courseName: String
    var professor: String
    var courseCode: String
    var credits: Int // 学分
    var courseDescription: String // 课程描述
    
    // 关系 - 上课时间列表
    @Relationship(deleteRule: .cascade)
    var classTimes: [ClassTime] = []
    
    // 关系 - 作业列表
    @Relationship(deleteRule: .cascade)
    var homeworkList: [Homework] = []
    
    // 关系 - 课程的学生
    @Relationship(deleteRule: .nullify)
    var students: [User] = []
    
    // 关系 - 课程的评论
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
    
    // 便捷方法：添加上课时间
    func addClassTime(dayOfWeek: Int, startTime: Date, endTime: Date, location: String = "") {
        let classTime = ClassTime(dayOfWeek: dayOfWeek, startTime: startTime, endTime: endTime, location: location)
        classTimes.append(classTime)
    }
    
    // 便捷方法：添加作业
    func addHomework(homeworkId: String, title: String, description: String, dueDate: Date, priority: Int = 3) {
        let homework = Homework(homeworkId: homeworkId, title: title, description: description, dueDate: dueDate, priority: priority)
        homeworkList.append(homework)
    }
    
    // 便捷方法：计算平均评分
    func averageRating() -> Double {
        guard !comments.isEmpty else { return 0.0 }
        let total = comments.reduce(0) { $0 + Double($1.rating) }
        return total / Double(comments.count)
    }
    
    // 便捷方法：获取未完成的作业
    func pendingHomeworks() -> [Homework] {
        return homeworkList.filter { !$0.isCompleted }
    }
}

