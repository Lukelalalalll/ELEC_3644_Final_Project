import SwiftUI
import SwiftData
import MapKit

struct ContentView: View {
    // 控制底部选中项
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 1. 首页
            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            // 2. 帖子页
            PostsView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Posts")
                }
                .tag(1)
            
            // 3. 地图页（修复绑定参数）
            MapView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "map.fill")
                    Text("Map")
                }
                .tag(2)

            // 4. 课程页
            CoursesView()
                .tabItem {
                    Image(systemName: "book.fill")
                    Text("Courses")
                }
                .tag(3)
            
            // 5. 个人页
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(4)
        }
    }
}

// 帖子页实现
struct PostsView: View {
    @Query private var posts: [Post]
    
    var body: some View {
        NavigationStack {
            List(posts) { post in
                VStack(alignment: .leading, spacing: 8) {
                    Text(post.title)
                        .font(.headline)
                    Text(post.content)
                        .font(.body)
                        .foregroundColor(.gray)
                    Text("Posted \(formatTimeAgo(post.postDate))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
            .navigationTitle("Posts")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        // 新建帖子逻辑
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
    
    // 时间格式化辅助方法
    private func formatTimeAgo(_ date: Date) -> String {
        let hours = Int(Date().timeIntervalSince(date) / 3600)
        if hours < 1 {
            return "just now"
        } else if hours < 24 {
            return "\(hours)h ago"
        } else {
            return "\(hours / 24)d ago"
        }
    }
}

// 课程页实现
struct CoursesView: View {
    @Query private var courses: [Course]
    
    var body: some View {
        NavigationStack {
            List(courses) { course in
                VStack(alignment: .leading, spacing: 4) {
                    Text(course.courseName)
                        .font(.headline)
                    Text("Professor: \(course.professor)")
                        .font(.subheadline)
                    Text("Credits: \(course.credits) | Code: \(course.courseCode)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 8)
            }
            .navigationTitle("My Courses")
        }
    }
}

// 预览
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .modelContainer(for: [User.self, Course.self, Post.self, Homework.self], inMemory: true)
    }
}
