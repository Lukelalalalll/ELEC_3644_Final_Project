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
    var userId: String          // Firebase Auth 的 uid
    var username: String
    var password: String        // 本地不存真实密码，登录后为空字符串即可
    var email: String
    var gender: String
    
    // 头像二进制数据（SwiftData 本地缓存用）
    var avatar: Data?
    
    // 加入日期
    var joinDate: Date
    
    // MARK: - Firebase 同步字段（非常重要！）
    // 用户在 Firebase 中选择的课程 ID 列表
    // 这个字段会在 Firestore 的 users/{uid} 文档里同步存储
    var enrolledCourseIds: [String] = []   // ← 新增这行！！！
    
    // MARK: - SwiftData 关系（离线使用）
    @Relationship(deleteRule: .cascade)
    var posts: [Post] = []
    
    @Relationship(deleteRule: .nullify)
    var courses: [Course] = []              // 本地缓存的完整 Course 对象（含课表、作业）
    
    @Relationship(deleteRule: .cascade)
    var postComments: [PostComment] = []
    
    @Relationship(deleteRule: .cascade)
    var courseComments: [CourseComment] = []
    
    @Relationship(deleteRule: .nullify)
    var likedPosts: [Post] = []
    
    @Relationship(deleteRule: .nullify)
    var likedComments: [PostComment] = []
    
    init(userId: String,
         username: String,
         password: String = "",
         email: String,
         gender: String,
         avatar: Data? = nil,
         joinDate: Date = Date(),
         enrolledCourseIds: [String] = []) {   // ← 新增参数
        self.userId = userId
        self.username = username
        self.password = password
        self.email = email
        self.gender = gender
        self.avatar = avatar
        self.joinDate = joinDate
        self.enrolledCourseIds = enrolledCourseIds   // ← 初始化
    }
    
    // MARK: - 便捷方法
    func daysSinceJoin() -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: joinDate, to: Date())
        return components.day ?? 0
    }
    
    func allHomeworks() -> [Homework] {
        return courses.flatMap { $0.homeworkList }
    }
    
    func dueSoonHomeworks() -> [Homework] {
        return allHomeworks().filter { $0.isDueSoon() }
    }
    
    func updateAvatar(_ imageData: Data?) {
        self.avatar = imageData
    }
    
    // 判断是否已经选过某门课
    func hasEnrolled(courseId: String) -> Bool {
        return enrolledCourseIds.contains(courseId)
    }
}
