
//  Homework.swift
//  ELEC_3644_Final_Project
//
//  Created by cccakkke on 2025/11/21.
//

import SwiftData
import Foundation

@Model
class Homework {
    var homeworkId: String
    var title: String
    var dueDate: Date // 截止日期
    
    // 关系 - 所属的课程
    var course: Course?
    
    init(homeworkId: String, title: String, dueDate: Date, course: Course? = nil) {
        self.homeworkId = homeworkId
        self.title = title
        self.dueDate = dueDate
        self.course = course
    }
    
    // 便捷方法：检查是否即将到期（3天内）
    func isDueSoon() -> Bool {
        let threeDays: TimeInterval = 3 * 24 * 60 * 60
        return dueDate.timeIntervalSinceNow <= threeDays
    }
}
