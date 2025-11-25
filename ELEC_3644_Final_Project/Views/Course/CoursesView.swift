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
    
    private var sampleCourses: [Course] {
        createSampleCourses()
    }
    
    var body: some View {
        NavigationView {
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
                        .onChange(of: searchText) { oldValue, newValue in
                            filterCourses()
                        }
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                
                if !searchText.isEmpty && !filteredCourses.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Search Results")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .padding(.horizontal)
                        
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredCourses) { course in
                                    NavigationLink(destination: CourseDetailView(course: course)) {
                                        CourseSearchResultCard(course: course)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Courses")
        }
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

struct CourseSearchResultCard: View {
    let course: Course
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Text(getCoursePrefix(course.courseCode))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(course.courseCode)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text(course.courseName)
                    .font(.subheadline)
                    .fontWeight(.regular)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text("Prof. \(course.professor)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("\(course.credits) credits")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(6)
                    
                    if !course.classTimes.isEmpty {
                        Text("\(course.classTimes.count) sessions")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.1))
                            .foregroundColor(.green)
                            .cornerRadius(6)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    private func getCoursePrefix(_ courseCode: String) -> String {
        if courseCode.count >= 4 {
            return String(courseCode.prefix(4)).uppercased()
        } else {
            return courseCode.uppercased()
        }
    }
}

struct CoursesView_Previews: PreviewProvider {
    static var previews: some View {
        CoursesView()
    }
}
