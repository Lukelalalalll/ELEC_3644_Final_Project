import SwiftUI
import MapKit
import CoreLocation
import SwiftData

struct HomeView: View {
    @Binding var selectedTab: Int
    @Query private var posts: [Post]
    @Query private var homeworks: [Homework]
    
    // 首页动态数据
    private var homePosts: [HomePost] {
        if !posts.isEmpty {
            return posts.map { post in
                HomePost(
                    title: post.title,
                    content: post.content,
                    time: formatTimeAgo(post.postDate)
                )
            }.sorted { $0.time < $1.time }
        } else {
            return [
                HomePost(title: "Final exam schedule released", content: "Check your courses for details", time: "2h ago"),
                HomePost(title: "Campus festival this weekend", content: "Live music and food trucks", time: "5h ago")
            ]
        }
    }
    
    // 校园地图配置
    private let campusRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 22.5429, longitude: 114.0596),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )
    
    private let previewAnnotations = [
        CampusAnnotation(name: "University Library", coordinate: CLLocationCoordinate2D(latitude: 22.4275, longitude: 114.2065)),
        CampusAnnotation(name: "Shaw College", coordinate: CLLocationCoordinate2D(latitude: 22.4258, longitude: 114.2032))
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 1. 学术提醒卡片
                    AcademicReminderCard()
                        .onTapGesture {
                            selectedTab = 3
                        }
                    
                    // 2. 地图预览模块（修复导航链接参数）
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Campus Map")
                                .font(.headline)
                            Spacer()
                            NavigationLink(destination: MapView(selectedTab: $selectedTab)) {  // 修复绑定参数
                                Text("View Full Map →")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Map(
                            coordinateRegion: .constant(campusRegion),
                            annotationItems: previewAnnotations
                        ) { annotation in
                            MapMarker(coordinate: annotation.coordinate, tint: .red)  // 替换MapPin为MapMarker
                        }
                        .frame(height: 180)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)
                    
                    // 3. 首页动态信息流
                    Text("Latest Updates")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    ForEach(homePosts) { post in
                        PostCard(post: post)
                    }
                }
                .padding(.vertical, 16)
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        // 跳转帖子创建页
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                    }
                }
            }
        }
    }
    
    // 格式化时间为"x小时前"
    private func formatTimeAgo(_ date: Date) -> String {
        let hours = Int(Date().timeIntervalSince(date) / 3600)
        return hours < 1 ? "Just now" : "\(hours)h ago"
    }
}

// 学术提醒卡片子视图
struct AcademicReminderCard: View {
    @Query private var homeworks: [Homework]
    
    // 计算本周待完成作业数
    private var pendingHomeworksCount: Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        let endOfWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: startOfWeek)!
        
        return homeworks.filter {
            !$0.isCompleted && $0.dueDate >= startOfWeek && $0.dueDate < endOfWeek
        }.count
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
            VStack(alignment: .leading, spacing: 8) {
                Text("Academic Deadlines")
                    .font(.headline)
                Text("\(pendingHomeworksCount) assignments due this week")
                    .font(.subheadline)
            }
            .padding()
        }
        .frame(height: 100)
        .padding(.horizontal)
    }
}

// 帖子卡片子视图
struct PostCard: View {
    let post: HomePost
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(post.title)
                .font(.headline)
            Text(post.content)
                .font(.body)
            Text(post.time)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(selectedTab: .constant(0))
            .modelContainer(for: [Post.self, Homework.self], inMemory: true)
    }
}
