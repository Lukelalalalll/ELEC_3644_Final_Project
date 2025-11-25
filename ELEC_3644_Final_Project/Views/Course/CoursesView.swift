import SwiftUI
import SwiftData
import FirebaseFirestore

struct CoursesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    
    @State private var searchText = ""
    @State private var filteredCourses: [Course] = []
    @State private var allCourses: [Course] = []
    @State private var userHomework: [Homework] = []
    @State private var isInitialLoading = true
    @State private var errorMessage: String?
    
    private var currentUser: User? {
        users.first
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 0)
                
                NavigationLink(destination: MyCoursesView()) {
                    HStack {
                        Image(systemName: "book.fill")
                            .resizable()
                            .frame(width: 20, height: 20)
                        Text("My Courses")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(.horizontal)
                
                NavigationLink(destination: HomeworkView()) {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .resizable()
                            .frame(width: 20, height: 20)
                        Text("Homework Deadlines")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
                }
                .padding(.horizontal)
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search by course name or code", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.search)
                        .onSubmit {
                            hideKeyboard()
                        }
                        .onChange(of: searchText) { oldValue, newValue in
                            filterCourses()
                        }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                if isInitialLoading {
                    ProgressView("Loading courses...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 50)
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
                } else if !searchText.isEmpty && !filteredCourses.isEmpty {

                    List(filteredCourses) { course in
                        NavigationLink {
                            CourseDetailView(course: course)
                        } label: {
                            CourseSearchRowView(course: course)
                        }
                    }
                    .listStyle(.plain)
                } else if !searchText.isEmpty && filteredCourses.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("Course not found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Try different keywords")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 50)
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
                }
                
                Spacer()
            }
            .navigationTitle("Courses")
            .refreshable {
                loadAllCoursesFromFirebase()
            }
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
                
                // 初始筛选（如果有搜索文本）
                if !self.searchText.isEmpty {
                    self.filterCourses()
                }
            }
        }
    }
    
    private func convertToCourse(from data: [String: Any], id: String) -> Course? {
        guard let courseName = data["courseName"] as? String,
              let professor = data["professor"] as? String,
              let courseCode = data["courseCode"] as? String else {
            print("❌ 缺少必需字段")
            return nil
        }
        
        // 处理 credits 字段
        let credits: Int
        if let creditsInt = data["credits"] as? Int {
            credits = creditsInt
        } else if let creditsString = data["credits"] as? String,
                  let creditsValue = Int(creditsString) {
            credits = creditsValue
        } else {
            print("❌ credits 字段格式错误")
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
        
        // 转换上课时间 - 修复字符串到数字的转换
        if let classTimes = data["classTimes"] as? [[String: Any]] {
            print("📅 找到 \(classTimes.count) 个上课时间段")
            for (index, classTimeData) in classTimes.enumerated() {
                print("🔍 处理第 \(index + 1) 个时间段: \(classTimeData)")
                
                // 修复：处理字符串类型的数字
                guard let dayOfWeekValue = classTimeData["dayOfWeek"],
                      let startTimeValue = classTimeData["startTime"],
                      let endTimeValue = classTimeData["endTime"],
                      let locationValue = classTimeData["location"] else {
                    print("❌ 时间段数据存在 nil 值")
                    continue
                }
                
                // 处理 dayOfWeek：可能是 String 或 Int
                let dayOfWeek: Int
                if let dayInt = dayOfWeekValue as? Int {
                    dayOfWeek = dayInt
                } else if let dayString = dayOfWeekValue as? String,
                          let dayIntValue = Int(dayString) {
                    dayOfWeek = dayIntValue
                } else {
                    print("❌ dayOfWeek 格式错误: \(dayOfWeekValue)")
                    continue
                }
                
                // 处理时间字符串
                guard let startTimeString = startTimeValue as? String,
                      let endTimeString = endTimeValue as? String,
                      let location = locationValue as? String else {
                    print("❌ 时间或位置字段格式错误")
                    continue
                }
                
                print("✅ 时间段数据完整: dayOfWeek=\(dayOfWeek), startTime=\(startTimeString), endTime=\(endTimeString), location=\(location)")
                
                let startTime = parseTimeString(startTimeString)
                let endTime = parseTimeString(endTimeString)
                
                print("🕒 转换后时间: startTime=\(startTime), endTime=\(endTime)")
                
                course.addClassTime(
                    dayOfWeek: dayOfWeek,
                    startTime: startTime,
                    endTime: endTime,
                    location: location
                )
                
                print("✅ 成功添加上课时间到课程对象")
            }
            
            // 检查课程对象中的 classTimes
            print("📋 课程对象中的 classTimes 数量: \(course.classTimes.count)")
            for (index, ct) in course.classTimes.enumerated() {
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                let startStr = formatter.string(from: ct.startTime)
                let endStr = formatter.string(from: ct.endTime)
                print("   \(index + 1). 星期\(ct.dayOfWeek) \(startStr)-\(endStr) @ \(ct.location)")
            }
        } else {
            print("❌ 没有找到 classTimes 字段或格式错误")
            print("   classTimes 数据: \(data["classTimes"] ?? "nil")")
            print("   classTimes 类型: \(type(of: data["classTimes"]))")
        }
        
        return course
    }
    
    private func parseTimeString(_ timeString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        if let date = formatter.date(from: timeString) {
            print("✅ 成功解析时间字符串 '\(timeString)' -> \(date)")
            return date
        } else {
            print("❌ 无法解析时间字符串 '\(timeString)'")
            return Date()
        }
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
    
    private func loadUserHomework() {
        guard let user = currentUser else { return }
        userHomework = user.allHomeworks().sorted { $0.dueDate < $1.dueDate }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// 使用类似 AddCourseView 的课程行视图
struct CourseSearchRowView: View {
    let course: Course
    
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
                
                if !course.classTimes.isEmpty {
                    HStack {
                        Text("\(course.classTimes.count) sessions")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.1))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }
                }
            }
            
            Spacer()
            
            
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

struct CoursesView_Previews: PreviewProvider {
    static var previews: some View {
        CoursesView()
    }
}


import UIKit

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
