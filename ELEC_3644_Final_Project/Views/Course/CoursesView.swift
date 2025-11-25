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
            VStack(spacing: 0) {
                VStack(spacing: 20) {
                    NavigationLink(destination: MyCoursesView()) {
                        HStack {
                            Image(systemName: "book.fill")
                                .resizable()
                                .frame(width: 26, height: 26)
                                .foregroundColor(.blue)
                            Text("My Courses")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 18))
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.blue.opacity(0.4), lineWidth: 1.5)
                        )
                    }
                    .padding(.horizontal, 20)

                    NavigationLink(destination: HomeworkView()) {
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .resizable()
                                .frame(width: 26, height: 26)
                                .foregroundColor(.orange)
                            Text("Homework Deadlines")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 18))
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 20)
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity)
                        .background(Color.orange.opacity(0.15))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.orange.opacity(0.4), lineWidth: 1.5)
                        )
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 12)
                .padding(.bottom, 32)
                .background(Color(.systemBackground))

                Divider()

                ScrollView {
                    LazyVStack(spacing: 16) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 18))
                                .foregroundColor(.gray)
                            TextField("Search by course name or code", text: $searchText)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .submitLabel(.search)
                                .onSubmit { hideKeyboard() }
                                .onChange(of: searchText) { _, _ in filterCourses() }
                        }
                        .padding(14)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal, 20)

                        if isInitialLoading {
                            ProgressView("Loading courses...")
                                .font(.title3)
                                .frame(maxWidth: .infinity, minHeight: 300)
                                .padding(.top, 60)
                        }
                        else if let errorMessage = errorMessage {
                            VStack(spacing: 20) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 56))
                                    .foregroundColor(.orange)
                                Text(errorMessage)
                                    .font(.title3)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                                Button("Retry") {
                                    loadAllCoursesFromFirebase()
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.large)
                            }
                            .frame(maxWidth: .infinity, minHeight: 300)
                            .padding(.top, 60)
                        }
                        else if !searchText.isEmpty && !filteredCourses.isEmpty {
                            ForEach(filteredCourses) { course in
                                NavigationLink(destination: CourseDetailView(course: course)) {
                                    CourseSearchRowView(course: course)
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 20)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(.systemBackground))
                                }
                                .listRowInsets(.init())
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                            }
                        }
                        else if !searchText.isEmpty && filteredCourses.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 64))
                                    .foregroundColor(.gray.opacity(0.6))
                                Text("Course not found")
                                    .font(.title2)
                                    .fontWeight(.medium)
                                Text("Try different keywords")
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 300)
                            .padding(.top, 60)
                        }
                        else {
                            VStack(spacing: 20) {
                                Image(systemName: "graduationcap.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.blue.opacity(0.8))
                                VStack(spacing: 8) {
                                    Text("Search for Courses")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                    Text("Enter course name or code to start searching")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .frame(maxWidth: .infinity, minHeight: 300)
                            .padding(.top, 60)
                        }
                    }
                }
            }
            .navigationTitle("Courses")
            .navigationBarTitleDisplayMode(.large)
            .ignoresSafeArea(.keyboard)
            .refreshable {
                await loadAllCoursesFromFirebase()
            }
            .onAppear {
                if allCourses.isEmpty {
                    loadAllCoursesFromFirebase()
                }
            }
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    self.errorMessage = "No courses found"
                    return
                }
                                
                var courses: [Course] = []
                
                for document in documents {
                    let data = document.data()
                    if let course = self.convertToCourse(from: data, id: document.documentID) {
                        courses.append(course)
                    }
                }
                
                self.allCourses = courses.sorted { $0.courseName < $1.courseName }
                
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
        
        if let classTimes = data["classTimes"] as? [[String: Any]] {
            for (index, classTimeData) in classTimes.enumerated() {
                
                guard let dayOfWeekValue = classTimeData["dayOfWeek"],
                      let startTimeValue = classTimeData["startTime"],
                      let endTimeValue = classTimeData["endTime"],
                      let locationValue = classTimeData["location"] else {
                    continue
                }
                
                let dayOfWeek: Int
                if let dayInt = dayOfWeekValue as? Int {
                    dayOfWeek = dayInt
                } else if let dayString = dayOfWeekValue as? String,
                          let dayIntValue = Int(dayString) {
                    dayOfWeek = dayIntValue
                } else {
                    continue
                }
                
                guard let startTimeString = startTimeValue as? String,
                      let endTimeString = endTimeValue as? String,
                      let location = locationValue as? String else {
                    continue
                }
                

                let startTime = parseTimeString(startTimeString)
                let endTime = parseTimeString(endTimeString)
                                
                course.addClassTime(
                    dayOfWeek: dayOfWeek,
                    startTime: startTime,
                    endTime: endTime,
                    location: location
                )
                
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
            return date
        } else {
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

struct CourseSearchRowView: View {
    let course: Course
    
    var body: some View {
        HStack(spacing: 12) {
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
