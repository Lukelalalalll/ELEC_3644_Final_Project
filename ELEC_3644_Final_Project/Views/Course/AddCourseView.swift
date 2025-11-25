import SwiftUI
import SwiftData
import FirebaseFirestore

struct AddCourseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    private var currentUser: User? {
        guard let currentUserId = UserDefaults.standard.string(forKey: "currentUserId") else {
            print("UserDefaults doesn't contain currentUserId，please login first")
            return nil
        }
        
        let predicate = #Predicate<User> { user in
            user.userId == currentUserId
        }
        
        let descriptor = FetchDescriptor<User>(predicate: predicate)
        
        do {
            let results = try modelContext.fetch(descriptor)
            if let user = results.first {
                print("find current login user → userId: \(user.userId), username: \(user.username)")
                return user
            } else {
                print("According to currentUserId=\(currentUserId) in local SwiftData cannot find user")
                return nil
            }
        } catch {
            print("Fetch current user failed: \(error)")
            return nil
        }
    }
    
    @State private var searchText = ""
    @State private var filteredCourses: [Course] = []
    @State private var allCourses: [Course] = []
    @State private var showConfirmation = false
    @State private var addedCourseName = ""
    @State private var isInitialLoading = true
    @State private var errorMessage: String?
    
    @State private var loadingCourseIds: Set<String> = []
    
    var body: some View {
        VStack(spacing: 0) {
            // 搜索栏
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search course name or course code", text: $searchText)
                    .onChange(of: searchText) {
                        filterCourses()
                    }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.top)
            
            // 课程列表
            List {
                if isInitialLoading {
                    ProgressView("Loading courses...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowSeparator(.hidden)
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            loadAllCoursesFromFirebase()
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
                    .listRowSeparator(.hidden)
                } else if filteredCourses.isEmpty && !searchText.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("Course not found")
                            .foregroundColor(.secondary)
                            .italic()
                        Text("Try different keywords")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 30)
                    .listRowSeparator(.hidden)
                } else if !searchText.isEmpty {
                    Section {
                        ForEach(filteredCourses) { course in
                            CourseRowView(
                                course: course,
                                isLoading: loadingCourseIds.contains(course.courseId),
                                onAdd: {
                                    addCourseToUser(course)
                                }
                            )
                            .disabled(loadingCourseIds.contains(course.courseId))
                        }
                    } header: {
                        Text("Available Courses (\(filteredCourses.count))")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "graduationcap.circle")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        VStack(spacing: 4) {
                            Text("Search for Courses")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text("Enter course name or code to start searching")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 50)
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .refreshable {
                loadAllCoursesFromFirebase()
            }
        }
        .navigationTitle("Add Courses")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") { dismiss() }
            }
        }
        .alert("Course Added Successfully", isPresented: $showConfirmation) {
            Button("OK") { }
        } message: {
            Text("\(addedCourseName) has been added to your course schedule!")
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .onAppear {
            if allCourses.isEmpty {
                loadAllCoursesFromFirebase()
            }
        }
    }
    
    private func loadAllCoursesFromFirebase() {
        isInitialLoading = true
        errorMessage = nil
        
        let db = Firestore.firestore()
        db.collection("courses").getDocuments { snapshot, error in
            DispatchQueue.main.async {
                self.isInitialLoading = false
                
                if let error = error {
                    self.errorMessage = "Failed to load courses: \(error.localizedDescription)"
                    print("❌ Firebase 加载错误: \(error)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.errorMessage = "No courses found"
                    print("❌ 没有找到任何课程文档")
                    return
                }
                
                print("✅ 从 Firebase 加载到 \(documents.count) 个课程文档")
                
                var courses: [Course] = []
                
                for document in documents {
                    let data = document.data()
                    if let course = self.convertToCourse(from: data, id: document.documentID) {
                        courses.append(course)
                    }
                }
                
                self.allCourses = courses.sorted { $0.courseName < $1.courseName }
                print("🎯 最终加载课程数量: \(courses.count)")
            }
        }
    }
    
    private func convertToCourse(from data: [String: Any], id: String) -> Course? {
        guard let courseName = data["courseName"] as? String,
              let professor = data["professor"] as? String,
              let courseCode = data["courseCode"] as? String else {
            return nil
        }
        
        let credits: Int
        if let creditsInt = data["credits"] as? Int {
            credits = creditsInt
        } else if let creditsString = data["credits"] as? String,
                  let creditsValue = Int(creditsString) {
            credits = creditsValue
        } else {
            return nil
        }
        
        let courseDescription = data["courseDescription"] as? String ?? ""
        
        let course = Course(
            courseId: id,
            courseName: courseName,
            professor: professor,
            courseCode: courseCode,
            credits: credits,
            courseDescription: courseDescription
        )
        
        // 转换上课时间
        if let classTimes = data["classTimes"] as? [[String: Any]] {
            for classTimeData in classTimes {
                if let dayOfWeek = classTimeData["dayOfWeek"] as? Int,
                   let startTimeString = classTimeData["startTime"] as? String,
                   let endTimeString = classTimeData["endTime"] as? String,
                   let location = classTimeData["location"] as? String {
                    
                    let startTime = parseTimeString(startTimeString)
                    let endTime = parseTimeString(endTimeString)
                    
                    course.addClassTime(
                        dayOfWeek: dayOfWeek,
                        startTime: startTime,
                        endTime: endTime,
                        location: location
                    )
                }
            }
        }
        
        return course
    }
    
    private func parseTimeString(_ timeString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: timeString) ?? Date()
    }
    
    private func filterCourses() {
        if searchText.isEmpty {
            filteredCourses = []
        } else {
            let searchLower = searchText.lowercased()
            filteredCourses = allCourses.filter { course in
                course.courseName.lowercased().contains(searchLower) ||
                course.courseCode.lowercased().contains(searchLower) ||
                course.professor.lowercased().contains(searchLower)
            }
        }
    }
    
    private func addCourseToUser(_ course: Course) {
        guard let user = currentUser else {
            errorMessage = "无法获取当前用户信息，请重新登录"
            return
        }
        
        // 设置当前课程的加载状态
        loadingCourseIds.insert(course.courseId)
        
        print("开始添加课程: \(course.courseId) 给用户: \(user.userId)")
        
        // 1. 检查 Firebase 是否已经选过这门课
        FirebaseService.shared.fetchEnrolledCourseIds(for: user.userId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let enrolledCourseIds):
                    if enrolledCourseIds.contains(course.courseId) {
                        print("课程已存在，跳过添加")
                        self.loadingCourseIds.remove(course.courseId)
                        self.addedCourseName = course.courseName
                        self.showConfirmation = true
                        return
                    }
                    
                    // 2. 添加到 Firebase
                    self.addCourseToFirebase(course, user: user)
                    
                case .failure(let error):
                    print("获取已选课程失败，尝试直接添加: \(error)")
                    self.addCourseToFirebase(course, user: user)
                }
            }
        }
    }
    
    private func addCourseToFirebase(_ course: Course, user: User) {
        FirebaseService.shared.addCourseToUser(
            userId: user.userId,
            courseId: course.courseId
        ) { result in
            DispatchQueue.main.async {
                // 移除加载状态
                self.loadingCourseIds.remove(course.courseId)
                
                switch result {
                case .success:
                    print("Firebase add course success")
                    
                    // 更新本地 SwiftData
                    if !user.enrolledCourseIds.contains(course.courseId) {
                        user.enrolledCourseIds.append(course.courseId)
                    }
                    
                    do {
                        try self.modelContext.save()
                        print("SwiftData store success")
                        self.addedCourseName = course.courseName
                        self.showConfirmation = true
                        
                        // 清空搜索
                        self.searchText = ""
                        self.filteredCourses = []
                    } catch {
                        print("SwiftData 保存失败: \(error)")
                        self.errorMessage = "本地保存失败"
                    }
                    
                case .failure(let error):
                    print("Firebase 添加课程失败: \(error)")
                    self.errorMessage = "添加失败：\(error.localizedDescription)"
                }
            }
        }
    }
}

// 独立的课程行视图，避免状态冲突
struct CourseRowView: View {
    let course: Course
    let isLoading: Bool
    let onAdd: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 课程信息
            VStack(alignment: .leading, spacing: 6) {
                Text(course.courseName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(course.courseCode)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text(course.professor)
                    Text("•")
                    Text("\(course.credits) credits")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 添加按钮
            Button(action: onAdd) {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isLoading)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationView {
        AddCourseView()
    }
}
