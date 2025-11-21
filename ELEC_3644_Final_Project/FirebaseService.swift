//
//  FirebaseService.swift
//  ELEC_3644_Final_Project
//
//  Created by cccakkke on 2025/11/21.
//

//
//  FirebaseService.swift
//  ELEC_3644_Final_Project
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    
    private let db = Firestore.firestore()
    
    // 注册用户
    func registerUser(username: String, email: String, password: String, gender: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let user = authResult?.user else {
                completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User creation failed"])))
                return
            }
            
            // 在 Firestore 中保存用户资料
            let userData: [String: Any] = [
                "userId": user.uid,
                "username": username,
                "email": email,
                "gender": gender,
                "joinDate": Timestamp(date: Date())
            ]
            
            self.db.collection("users").document(user.uid).setData(userData) { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    // 创建本地 User 对象（不存储密码）
                    let localUser = User(
                        userId: user.uid,
                        username: username,
                        password: "", // 不在本地存储密码
                        email: email,
                        gender: gender
                    )
                    completion(.success(localUser))
                }
            }
        }
    }
    
    // 登录用户
    func loginUser(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let user = authResult?.user else {
                completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Login failed"])))
                return
            }
            
            // 从 Firestore 获取用户资料
            self.getUserData(userId: user.uid) { result in
                completion(result)
            }
        }
    }
    
    // 获取用户资料
    private func getUserData(userId: String, completion: @escaping (Result<User, Error>) -> Void) {
        db.collection("users").document(userId).getDocument { document, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let document = document, document.exists,
                  let data = document.data() else {
                completion(.failure(NSError(domain: "FirebaseService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User data not found"])))
                return
            }
            
            let username = data["username"] as? String ?? ""
            let email = data["email"] as? String ?? ""
            let gender = data["gender"] as? String ?? "Male"
            
            let user = User(
                userId: userId,
                username: username,
                password: "", // 不在本地存储密码
                email: email,
                gender: gender
            )
            
            completion(.success(user))
        }
    }
    
    // 检查用户名是否唯一
    func checkUsernameUnique(_ username: String, completion: @escaping (Bool) -> Void) {
        db.collection("users")
            .whereField("username", isEqualTo: username)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error checking username: \(error)")
                    completion(false)
                    return
                }
                
                completion(snapshot?.documents.isEmpty ?? true)
            }
    }
    
    // 登出
    func logout() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out: \(error)")
        }
    }
    
    // 获取当前用户 - 这个方法应该已经存在了！
    func getCurrentUser(completion: @escaping (User?) -> Void) {
        if let currentUser = Auth.auth().currentUser {
            self.getUserData(userId: currentUser.uid) { result in
                switch result {
                case .success(let user):
                    completion(user)
                case .failure:
                    completion(nil)
                }
            }
        } else {
            completion(nil)
        }
    }
}
