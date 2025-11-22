//
//  CoursesView.swift
//  ELEC_3644_Final_Project
//
//  Created by cccakkke on 2025/11/20.
//


import SwiftUI
import SwiftData
struct CoursesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    @Query private var courses: [Course]
    
    @State private var searchText = ""
    @State private var filteredCourses: [Course] = []
    @State private var userHomework: [Homework] = []
    
    private var currentUser: User? {
        users.first
    }
    
    // 获取 CourseData 中的课程
    private var sampleCourses: [Course] {
        createSampleCourses()
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // 搜索框
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
                
                // 搜索结果列表
                if !searchText.isEmpty && !filteredCourses.isEmpty {
                    List {
                        Section(header: Text("Search Results")) {
                            ForEach(filteredCourses) { course in
                                NavigationLink(destination: CourseDetailView(course: course)) {
                                    VStack(alignment: .leading) {
                                        Text(course.courseName)
                                            .font(.headline)
                                        Text(course.courseCode)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        Text("Prof. \(course.professor)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .frame(height: min(CGFloat(filteredCourses.count * 70), 200))
                    .listStyle(PlainListStyle())
                }
                
                // 顶部：Weekly Course Schedule 按钮
                NavigationLink(destination: CoursesScheduleView()) {
                    HStack {
                        Image(systemName: "calendar")
                            .resizable()
                            .frame(width: 20, height: 20)
                        Text("Weekly Course Schedule")
                            .font(.headline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                
                // 作业 deadline 列表
                List {
                    Section(header: Text("Assignments Deadlines")) {
                        if userHomework.isEmpty {
                            Text("No upcoming assignments")
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            ForEach(userHomework, id: \.homeworkId) { homework in
                                HStack {
                                    Image(systemName: homework.isDueSoon() ? "exclamationmark.triangle.fill" : "clock")
                                        .resizable()
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(homework.isDueSoon() ? .orange : .primary)
                                    
                                    VStack(alignment: .leading) {
                                        Text(homework.title)
                                            .font(.headline)
                                        Text("Due: \(formatDate(homework.dueDate))")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        if let courseName = homework.course?.courseName {
                                            Text(courseName)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    
                    // 添加课程按钮
                    NavigationLink(destination: AddCourseView()) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.blue)
                            Text("Add New Course")
                                .foregroundColor(.primary)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Courses")
            .onAppear {
                loadUserHomework()
            }
            // 添加底部内边距以避免与 TabBar 重叠
            .padding(.bottom, 80)
        }
    }
    
    private func filterCourses() {
        if searchText.isEmpty {
            filteredCourses = []
        } else {
            // 只搜索 CourseData 中的课程
            filteredCourses = sampleCourses.filter { course in
                course.courseName.localizedCaseInsensitiveContains(searchText) ||
                course.courseCode.localizedCaseInsensitiveContains(searchText)
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
struct CoursesScheduleView: View {
    var body: some View {
        Text("Weekly Course Schedule View")
            .navigationTitle("Weekly Schedule")
    }
}

struct CoursesView_Previews: PreviewProvider {
    static var previews: some View {
        CoursesView()
    }
}
