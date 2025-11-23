// User.swift
import Foundation
import SwiftData

@Model
final class User {
    var userId: String
    var username: String
    var password: String
    var email: String
    var gender: String?
    var avatar: Data?
    var joinDate: Date
    var posts: [Post] = [] // 移除@Relationship
    var courseComments: [CourseComment] = [] // 移除@Relationship
    var postComments: [PostComment] = [] // 移除@Relationship
    var courses: [Course] = [] // 移除@Relationship
    
    init(userId: String, username: String, password: String, email: String, gender: String? = nil, avatar: Data? = nil, joinDate: Date = Date()) {
        self.userId = userId
        self.username = username
        self.password = password
        self.email = email
        self.gender = gender
        self.avatar = avatar
        self.joinDate = joinDate
    }
}
