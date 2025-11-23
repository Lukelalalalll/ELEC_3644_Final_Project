import SwiftUI
import PhotosUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    
    // 当前用户（实际项目中应替换为登录用户逻辑）
    private var currentUser: User? {
        users.first
    }
    
    // 存储选中的头像图片
    @State private var selectedImage: UIImage?
    // 相册选择器状态
    @State private var showingImagePicker = false
    // 图片选择配置
    @State private var imageSelection: PhotosPickerItem? = nil
    
    // 获取当前用户的课程（通过用户关联筛选）
    private var userCourses: [Course] {
        currentUser?.courses ?? []
    }
    
    // 在 ProfileView 中
    private var userHomeworks: [Homework] {
        userCourses.flatMap { $0.homeworks }  // 现在可以正确访问 course.homeworks 了
    }
    
    // 即将到来的截止日期（使用Deadline模型转换）
    private var upcomingDeadlines: [Deadline] {
        userHomeworks.filter { $0.dueDate >= Date() }
            .sorted { $0.dueDate < $1.dueDate }
            .map { Deadline(from: $0) }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 个人资料卡片
                if let user = currentUser {
                    ProfileCard(
                        user: user,
                        selectedImage: $selectedImage,
                        showingImagePicker: $showingImagePicker,
                        imageSelection: $imageSelection
                    )
                } else {
                    Text("No user data available")
                        .foregroundColor(.gray)
                }
                
                // 选课信息
                Section(header: Text("Enrolled Courses").font(.headline)) {
                    if !userCourses.isEmpty {
                        ForEach(userCourses) { course in
                            NavigationLink(value: course) {
                                Text(course.courseName)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(8)
                            }
                        }
                    } else {
                        Text("No enrolled courses")
                            .foregroundColor(.gray)
                            .padding()
                    }
                }
                
                // DDL信息
                Section(header: Text("Upcoming Deadlines").font(.headline)) {
                    if !upcomingDeadlines.isEmpty {
                        ForEach(upcomingDeadlines) { deadline in
                            VStack(alignment: .leading) {
                                Text(deadline.course)
                                    .font(.subheadline)
                                Text("\(deadline.task) - \(deadline.date)")
                                    .font(.body)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    } else {
                        Text("No upcoming deadlines")
                            .foregroundColor(.gray)
                            .padding()
                    }
                }
                
                // 设置按钮
                Button(action: {
                    // 跳转设置页逻辑
                }) {
                    Text("Settings")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                // 测试用：添加用户按钮（实际项目中移除）
                Button(action: {
                    addTestUser()
                }) {
                    Text("Add Test User")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
        }
        .navigationTitle("Profile")
        .navigationDestination(for: Course.self) { course in
            // 课程详情页（可根据需求实现）
            Text("\(course.courseName) Details")
                .navigationTitle(course.courseName)
        }
        .onAppear {
            // 加载用户头像
            loadUserAvatar()
        }
        // 监听图片选择变化
        .onChange(of: imageSelection) { newItem in
            Task {
                await handleImageSelection(newItem)
            }
        }
    }
    
    // 加载用户头像
    private func loadUserAvatar() {
        guard let avatarData = currentUser?.avatar,
              let uiImage = UIImage(data: avatarData) else { return }
        selectedImage = uiImage
    }
    
    // 处理图片选择
    private func handleImageSelection(_ newItem: PhotosPickerItem?) async {
        guard let data = try? await newItem?.loadTransferable(type: Data.self),
              let uiImage = UIImage(data: data) else { return }
        
        selectedImage = uiImage
        currentUser?.avatar = data
        try? modelContext.save()
    }
    
    // 在 ProfileView 的 addTestUser() 方法中
    private func addTestUser() {
        let testUser = User(
            userId: "TEST-\(UUID().uuidString.prefix(6))",
            username: "Test User",
            password: "testpass",
            email: "test@example.com",
            gender: "Other",
            joinDate: Date()
        )
        
        // 添加测试课程
        let testCourse = Course(
            courseId: "CS-\(Int.random(in: 100...999))",
            courseName: "Mobile App Development",
            professor: "Dr. Test",
            courseCode: "CS-\(Int.random(in: 100...999))",
            credits: 3,
            courseDescription: "Learn iOS app development with SwiftUI"
        )
        modelContext.insert(testCourse)
        
        // 添加测试作业
        let testHomework = Homework(
            homeworkId: "HW-\(UUID().uuidString.prefix(4))",
            title: "SwiftUI Project",
            dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
            course: testCourse
        )
        modelContext.insert(testHomework)
        
        // 关键：将作业添加到课程的homeworks数组（双向关联）
        testCourse.homeworks.append(testHomework)  // 新增这一行
        
        // 关联用户和课程
        testUser.courses.append(testCourse)
        modelContext.insert(testUser)
        
        try? modelContext.save()
    }
}

// 个人资料卡片子视图
struct ProfileCard: View {
    let user: User
    @Binding var selectedImage: UIImage?
    @Binding var showingImagePicker: Bool
    @Binding var imageSelection: PhotosPickerItem?
    
    var body: some View {
        VStack(spacing: 12) {
            // 头像
            ZStack {
                if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 160, height: 160)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                        .shadow(radius: 5)
                } else if let avatarData = user.avatar,
                          let avatarImage = UIImage(data: avatarData) {
                    Image(uiImage: avatarImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 160, height: 160)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 4))
                        .shadow(radius: 5)
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 160))
                        .foregroundColor(.blue)
                }
            }
            .onTapGesture {
                showingImagePicker = true
            }
            .sheet(isPresented: $showingImagePicker) {
                PhotosPicker(
                    selection: $imageSelection,
                    matching: .images,
                    preferredItemEncoding: .automatic
                ) {
                    Text("Choose Profile Image")
                        .foregroundColor(.blue)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .presentationDetents([.medium])
                .presentationBackground(Color.white)
            }
            
            // 个人信息
            Text(user.username)
                .font(.title)
            Text("ID: \(user.userId) | Email: \(user.email)")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            // 加入日期
            Text("Joined: \(DateFormatters.shortDate.string(from: user.joinDate))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
    }
}

// 预览
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: User.self, Course.self, Homework.self, configurations: config)
        
        // 添加测试用户
        let testUser = User(
            userId: "2023001",
            username: "Jane Doe",
            password: "test123",
            email: "jane@example.com",
            gender: "Female",
            joinDate: Date()
        )
        
        // 添加测试课程
        let testCourse = Course(
            courseId: "CS101",
            courseName: "Introduction to Programming",
            professor: "Dr. Smith",
            courseCode: "CS101",
            credits: 4
        )
        container.mainContext.insert(testCourse)
        
        // 添加测试作业
        let testHomework = Homework(
            homeworkId: "HW001",
            title: "Array Exercise",
            dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date())!,
            course: testCourse
        )
        container.mainContext.insert(testHomework)
        
        // 关联用户和课程
        testUser.courses.append(testCourse)
        container.mainContext.insert(testUser)
        
        return NavigationStack {
            ProfileView()
                .modelContainer(container)
        }
    }
}
