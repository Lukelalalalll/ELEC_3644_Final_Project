import SwiftUI
import SwiftData

struct AddCourseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var users: [User]
    @State private var searchText = ""
    @State private var filteredCourses: [Course] = []
    @State private var showConfirmation = false
    @State private var addedCourseName = ""
    
    private var currentUser: User? {
        users.first
    }
    
    // 获取 CourseData 中的课程
    private var sampleCourses: [Course] {
        createSampleCourses()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 搜索栏
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search by course name or code", text: $searchText)
                    .onChange(of: searchText) { oldValue, newValue in
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
                    Text("No courses found")
                        .foregroundColor(.secondary)
                        .italic()
                        .frame(maxWidth: .infinity, alignment: .center)
                } else if !searchText.isEmpty {
                    Section(header: Text("Available Courses")) {
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
                                
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                addCourseToUser(course)
                            }
                        }
                    }
                } else {
                    Text("Enter course name or code to search")
                        .foregroundColor(.secondary)
                        .italic()
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .listStyle(PlainListStyle())
        }
        .navigationTitle("Add Course")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    dismiss()
                }
            }
        }
        .alert("Course Added", isPresented: $showConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("\(addedCourseName) has been added to your courses.")
        }
    }
    
    private func filterCourses() {
        if searchText.isEmpty {
            filteredCourses = []
        } else {
            // 从样本课程中搜索
            filteredCourses = sampleCourses.filter { course in
                course.courseName.localizedCaseInsensitiveContains(searchText) ||
                course.courseCode.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func addCourseToUser(_ course: Course) {
        guard let user = currentUser else { return }
        
        // 检查是否已经添加了该课程
        if user.courses.contains(where: { $0.courseId == course.courseId }) {
            addedCourseName = course.courseName
            showConfirmation = true
            return
        }
        
        // 创建课程的深拷贝以避免数据冲突
        let newCourse = Course(
            courseId: course.courseId,
            courseName: course.courseName,
            professor: course.professor,
            courseCode: course.courseCode,
            credits: course.credits,
            courseDescription: course.courseDescription
        )
        
        // 复制上课时间
        for classTime in course.classTimes {
            let newClassTime = ClassTime(
                dayOfWeek: classTime.dayOfWeek,
                startTime: classTime.startTime,
                endTime: classTime.endTime,
                location: classTime.location,
                course: newCourse
            )
            newCourse.classTimes.append(newClassTime)
        }
        
        // 复制作业
        for homework in course.homeworkList {
            let newHomework = Homework(
                homeworkId: homework.homeworkId,
                title: homework.title,
                dueDate: homework.dueDate,
                course: newCourse
            )
            newCourse.homeworkList.append(newHomework)
        }
        
        // 添加到用户课程列表
        user.courses.append(newCourse)
        
        // 保存到模型上下文
        modelContext.insert(newCourse)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to save context: \(error)")
        }
        
        // 显示确认信息
        addedCourseName = course.courseName
        showConfirmation = true
        
        // 添加成功后清空搜索
        searchText = ""
        filteredCourses = []
    }
}

struct AddCourseView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AddCourseView()
        }
    }
}

#Preview {
    AddCourseView()
}
