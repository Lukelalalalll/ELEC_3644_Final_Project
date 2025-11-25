import SwiftUI
import SwiftData
import FirebaseFirestore

struct HomeworkView: View {
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
    
    @State private var userHomeworks: [Homework] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading homework...")
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
                        loadUserHomeworks()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if userHomeworks.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No homework yet")
                        .font(.title2)
                        .fontWeight(.medium)
                    Text("You don't have any homework from your courses")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(groupedHomeworks.keys.sorted(), id: \.self) { status in
                        Section(header: Text(status)) {
                            ForEach(groupedHomeworks[status] ?? []) { homework in
                                HomeworkCardView(homework: homework)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            }
                        }
                    }
                }
                .listStyle(.plain)
                
                Spacer()
                    .frame(height: 70)
            }
        }
        .navigationTitle("Homework Deadlines")
        .navigationBarTitleDisplayMode(.large)
        .onAppear(perform: loadUserHomeworks)
        .refreshable {
            await refreshHomeworks()
        }
    }

    private var groupedHomeworks: [String: [Homework]] {
        let now = Date()
        let calendar = Calendar.current
        
        var grouped: [String: [Homework]] = [
            "Overdue": [],
            "Due Today": [],
            "Due This Week": [],
            "Future": []
        ]
        
        for homework in userHomeworks {
            let dueDate = homework.dueDate
            
            if dueDate < now {
                grouped["Overdue"]?.append(homework)
            } else if calendar.isDateInToday(dueDate) {
                grouped["Due Today"]?.append(homework)
            } else if calendar.isDate(dueDate, equalTo: now, toGranularity: .weekOfYear) {
                grouped["Due This Week"]?.append(homework)
            } else {
                grouped["Future"]?.append(homework)
            }
        }

        return grouped.filter { !$0.value.isEmpty }
    }
    
    private func refreshHomeworks() async {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                self.loadUserHomeworks()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    continuation.resume()
                }
            }
        }
    }
    
    private func loadUserHomeworks() {
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
                case .success(let courseIds):
                    print("User enrolled in \(courseIds.count) courses: \(courseIds)")
                    
                    if courseIds.isEmpty {
                        self.userHomeworks = []
                        self.isLoading = false
                        return
                    }
                    
                    self.fetchCoursesWithHomeworks(courseIds: courseIds)
                    
                case .failure(let error):
                    self.errorMessage = "Failed to load enrolled courses: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func fetchCoursesWithHomeworks(courseIds: [String]) {
        let db = Firestore.firestore()
        var allHomeworks: [Homework] = []
        var completedRequests = 0
        
        for courseId in courseIds {
            db.collection("courses").document(courseId).getDocument { document, error in
                DispatchQueue.main.async {
                    completedRequests += 1
                    
                    if let error = error {
                    } else if let document = document, document.exists {
                        if let courseData = document.data(),
                           let homeworksData = courseData["homeworks"] as? [[String: Any]] {
                            
                            
                            for homeworkData in homeworksData {
                                if let homework = self.parseHomework(from: homeworkData, courseId: courseId, courseData: courseData) {
                                    allHomeworks.append(homework)
                                }
                            }
                        } else {
                        }
                    } else {
                    }
                    
                    if completedRequests == courseIds.count {
                        self.userHomeworks = allHomeworks.sorted { $0.dueDate < $1.dueDate }
                        self.isLoading = false
                    }
                }
            }
        }
    }
    
    private func parseHomework(from homeworkData: [String: Any], courseId: String, courseData: [String: Any]) -> Homework? {
        guard let homeworkId = homeworkData["homeworkId"] as? String,
              let title = homeworkData["title"] as? String,
              let dueDateString = homeworkData["dueDate"] as? String else {
            return nil
        }
        
        let dateFormatter = ISO8601DateFormatter()
        guard let dueDate = dateFormatter.date(from: dueDateString) else {
            return nil
        }
        
        let courseName = courseData["courseName"] as? String ?? "Unknown Course"
        let courseCode = courseData["courseCode"] as? String ?? "Unknown Code"
        let professor = courseData["professor"] as? String ?? "Unknown Professor"
        
        let course = Course(
            courseId: courseId,
            courseName: courseName,
            professor: professor,
            courseCode: courseCode,
            credits: 0,
            courseDescription: ""
        )
        
        let homework = Homework(
            homeworkId: homeworkId,
            title: title,
            dueDate: dueDate,
            course: course
        )
        
        return homework
    }
}

struct HomeworkCardView: View {
    let homework: Homework
    
    private var dueDateText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: homework.dueDate)
    }
    
    private var timeRemainingText: String {
        let now = Date()
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day, .hour], from: now, to: homework.dueDate)
        
        if let days = components.day, days > 0 {
            return "\(days) day\(days == 1 ? "" : "s") left"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours) hour\(hours == 1 ? "" : "s") left"
        } else {
            return "Due now"
        }
    }
    
    private var statusColor: Color {
        let now = Date()
        let calendar = Calendar.current
        
        if homework.dueDate < now {
            return .red
        } else if calendar.isDateInToday(homework.dueDate) {
            return .orange
        } else if calendar.isDate(homework.dueDate, equalTo: now, toGranularity: .weekOfYear) {
            return .yellow
        } else {
            return .green
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if let course = homework.course {
                    Text(course.courseCode)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text(timeRemainingText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.2))
                    .foregroundColor(statusColor)
                    .cornerRadius(6)
            }
            
            Text(homework.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Due: \(dueDateText)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if homework.isDueSoon() {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
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
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

#Preview {
    NavigationStack {
        HomeworkView()
    }
    .modelContainer(for: [User.self, Course.self], inMemory: true)
}
