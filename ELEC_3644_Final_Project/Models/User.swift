//
//  UserModel.swift
//  ELEC_3644_Final_Project
//
//  Created by cccakkke on 2025/11/21.
//


import SwiftData
import Foundation

@Model
class User {
    var userId: String // 新增：用户ID
    var username: String
    var password: String
    var email: String // 新增：邮箱
    var gender: String
    var avatar: Data? // 用户头像，存储为二进制数据
    var joinDate: Date
    
    // 关系 - 用户发的帖子
    @Relationship(deleteRule: .cascade)
    var posts: [Post] = []
    
    // 关系 - 用户的课程
    @Relationship(deleteRule: .nullify)
    var courses: [Course] = []
    
    // 关系 - 用户发的帖子评论
    @Relationship(deleteRule: .cascade)
    var postComments: [PostComment] = []
    
    // 关系 - 用户发的课程评论
    @Relationship(deleteRule: .cascade)
    var courseComments: [CourseComment] = []
    
    init(userId: String, username: String, password: String, email: String, gender: String, avatar: Data? = nil) {
        self.userId = userId
        self.username = username
        self.password = password
        self.email = email
        self.gender = gender
        self.avatar = avatar
        self.joinDate = Date()
    }
    
    // 便捷方法：用户加入天数
    func daysSinceJoin() -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: joinDate, to: Date())
        return components.day ?? 0
    }
    
    // 便捷方法：获取用户的所有作业
    func allHomeworks() -> [Homework] {
        return courses.flatMap { $0.homeworkList }
    }
    
    // 便捷方法：获取即将到期的作业
    func dueSoonHomeworks() -> [Homework] {
        return allHomeworks().filter { $0.isDueSoon() }
    }
}
