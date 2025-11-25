import SwiftUI
import SwiftData
import FirebaseFirestore

struct MyCoursesView: View {
    @Environment(\.modelContext) private var modelContext
    
    private var currentUser: User? {
        guard let currentUserId = UserDefaults.standard.string(forKey: "currentUserId") else {
            print("No currentUserId in UserDefaults, please login again")
            return nil
        }
        
        let predicate = #Predicate<User> { $0.userId == currentUserId }
        let descriptor = FetchDescriptor<User>(predicate: predicate)
        
        do {
            let results = try modelContext.fetch(descriptor)
            return results.first
        } catch {
            print("Failed to fetch current user: \(error)")
            return nil
        }
    }
    
    @State private var enrolledCourses: [Course] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingAddCourse = false
    @State private var showingDeleteAlert = false
    @State private var courseToDelete: Course?
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading courses...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    Text("Failed to load")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text(errorMessage)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Retry") {
                        loadEnrolledCourses()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if enrolledCourses.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No courses yet")
                        .font(.title2)
                        .fontWeight(.medium)
                    Text("You haven't added any courses")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    
                    Button {
                        showingAddCourse = true
                    } label: {
                        Label("Add Course", systemImage: "plus")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.accentColor)
                            .cornerRadius(30)
                    }
                    .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(enrolledCourses) { course in
                        NavigationLink(destination: CourseDetailView(course: course)) {
                            CourseCardView(
                                course: course,
                                onDelete: {
                                    courseToDelete = course
                                    showingDeleteAlert = true
                                }
                            )
                        }
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .listStyle(.plain)
                Spacer()
                    .frame(height: 60)
            }
        }
        .navigationTitle("My Courses")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddCourse = true
                } label: {
                    Image(systemName: "plus")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
        }
        .sheet(isPresented: $showingAddCourse) {
            NavigationStack {
                AddCourseView()
            }
        }
        .alert("Delete Course", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                courseToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let course = courseToDelete {
                    deleteCourse(course)
                }
            }
        } message: {
            if let course = courseToDelete {
                Text("Are you sure you want to remove \"\(course.courseName)\" from your courses?")
            }
        }
        .onAppear(perform: loadEnrolledCourses)
        .refreshable {
            await refreshCourses()
        }
    }
    
    private func refreshCourses() async {
        // 模拟加载延迟
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒延迟
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                self.loadEnrolledCourses()
                // 假设加载需要一些时间，这里等待加载完成
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    continuation.resume()
                }
            }
        }
    }
    
    private func loadEnrolledCourses() {
        guard let user = currentUser else {
            errorMessage = "Unable to get user info, please login again"
            isLoading = false
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        FirebaseService.shared.fetchEnrolledCourseIds(for: user.userId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let ids):
                    let allSampleCourses = createSampleCourses()
                    let matched = allSampleCourses.filter { ids.contains($0.courseId) }
                    self.enrolledCourses = matched.sorted { $0.courseName < $1.courseName }
                    self.isLoading = false
                    
                case .failure(let error):
                    self.errorMessage = "Failed to load courses: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func deleteCourse(_ course: Course) {
        guard let user = currentUser else {
            errorMessage = "Unable to get user info, please login again"
            return
        }
        
        // 从 Firebase 中删除课程 ID
        FirebaseService.shared.db.collection("users").document(user.userId).updateData([
            "enrolledCourseIds": FieldValue.arrayRemove([course.courseId])
        ]) { error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Failed to delete course: \(error.localizedDescription)"
                } else {
                    // 从本地列表中删除课程
                    withAnimation {
                        self.enrolledCourses.removeAll { $0.courseId == course.courseId }
                    }
                    print("✅ Successfully deleted course: \(course.courseName)")
                }
            }
        }
    }
}

struct CourseCardView: View {
    let course: Course
    var onDelete: (() -> Void)?
    
    private var classTimesText: String {
        if course.classTimes.isEmpty { return "No schedule yet" }
        
        let dayNames = ["", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        return course.classTimes.map { ct in
            let day = dayNames.indices.contains(ct.dayOfWeek) ? dayNames[ct.dayOfWeek] : "Unknown"
            let start = formatter.string(from: ct.startTime)
            let end = formatter.string(from: ct.endTime)
            let location = ct.location.isEmpty ? "TBD" : ct.location
            return "\(day) \(start)–\(end) @ \(location)"
        }
        .joined(separator: "\n")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 顶部标题行
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(course.courseId.uppercased())
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(course.courseName)
                        .font(.title3)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // 删除按钮 - 放在卡片内部右上角
                if let onDelete = onDelete {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.red)
                            .frame(width: 32, height: 32)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            HStack {
                Text(course.professor)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(course.credits) credits")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.accentColor.opacity(0.15))
                    .foregroundColor(.accentColor)
                    .cornerRadius(8)
            }
            
            // 上课时间
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "clock")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Schedule")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    Text(classTimesText)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .lineSpacing(4)
                }
            }
            
            if !course.courseDescription.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "text.alignleft")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        Text(course.courseDescription)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .lineLimit(4)
                    }
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(30)
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    NavigationStack {
        MyCoursesView()
            .modelContainer(for: [User.self, Course.self], inMemory: true)
    }
}
