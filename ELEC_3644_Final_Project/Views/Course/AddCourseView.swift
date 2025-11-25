import SwiftUI
import SwiftData

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
    
    private var sampleCourses: [Course] {
        createSampleCourses()
    }
    
    @State private var searchText = ""
    @State private var filteredCourses: [Course] = []
    @State private var showConfirmation = false
    @State private var addedCourseName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 0) {
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
                if filteredCourses.isEmpty && !searchText.isEmpty {
                    Text("Course not found")
                        .foregroundColor(.secondary)
                        .italic()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if !searchText.isEmpty {
                    Section("Selectable Courses") {
                        ForEach(filteredCourses) { course in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(course.courseName)
                                        .font(.headline)
                                    Text("\(course.courseCode) · \(course.professor)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                
                                if isLoading {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.blue)
                                        .font(.title2)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                addCourseToUser(course)
                            }
                        }
                    }
                } else {
                    Text("Input the course name/code to start searching...")
                        .foregroundColor(.secondary)
                        .italic()
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .listStyle(.plain)
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
            Text("\(addedCourseName) added to your course schedule successfully!")
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("Sure") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .onAppear {
            filterCourses()
        }
        // 添加点击空白处收回键盘的功能
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    private func filterCourses() {
        if searchText.isEmpty {
            filteredCourses = []
        } else {
            filteredCourses = sampleCourses.filter { course in
                course.courseName.localizedCaseInsensitiveContains(searchText) ||
                course.courseCode.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func addCourseToUser(_ course: Course) {
        guard let user = currentUser else {
            errorMessage = "无法获取当前用户信息，请重新登录"
            return
        }
        
        print("开始添加课程: \(course.courseId) 给用户: \(user.userId) (\(user.username))")
        
        isLoading = true
        
        // 1. 检查 Firebase 是否已经选过这门课
        FirebaseService.shared.fetchEnrolledCourseIds(for: user.userId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let enrolledCourseIds):
                    print("Firebase 中已选课程: \(enrolledCourseIds)")
                    
                    if enrolledCourseIds.contains(course.courseId) {
                        print("课程已存在，跳过添加")
                        isLoading = false
                        addedCourseName = course.courseName
                        showConfirmation = true
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
                self.isLoading = false
                
                switch result {
                case .success:
                    print("Firebase add course success")
                    
                    if !user.enrolledCourseIds.contains(course.courseId) {
                        user.enrolledCourseIds.append(course.courseId)
                    }
                    
                    do {
                        try self.modelContext.save()
                        print("SwiftData store success")
                        self.addedCourseName = course.courseName
                        self.showConfirmation = true
                        
                        self.searchText = ""
                        self.filteredCourses = []
                    } catch {
                        print("SwiftData 保存失败: \(error)")
                        self.errorMessage = "本地保存失败"
                    }
                    
                case .failure(let error):
                    print("Firebase 添加课程失败: \(error)")
                    self.errorMessage = "fail to add：\(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    AddCourseView()
}
