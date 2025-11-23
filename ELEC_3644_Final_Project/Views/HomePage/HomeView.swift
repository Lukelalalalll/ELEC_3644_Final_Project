import SwiftUI
import MapKit
import CoreLocation

struct HomeView: View {
    @Binding var selectedTab: Int
    @State private var locationManager = LocationManager()
    
    // 静态新闻数据
    private let staticNews: [NewsItem] = [
        NewsItem(title: "Final exam schedule released", content: "Check your courses for details", time: "2h ago"),
        NewsItem(title: "Campus festival this weekend", content: "Live music and food trucks", time: "5h ago"),
        NewsItem(title: "Library extended hours", content: "Open until midnight during finals", time: "1d ago"),
        NewsItem(title: "New student portal launched", content: "Access all services in one place", time: "2d ago")
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
                    
                    // 2. 图书馆快速访问按钮 - 使用 NavigationLink 实现全屏跳转
                    NavigationLink(destination: LibraryView()) {
                        LibraryQuickAccessCard()
                    }
                    .buttonStyle(PlainButtonStyle()) // 移除默认的按钮样式
                    
                    // 3. 简化地图预览模块 - 使用实时位置
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Campus Map")
                                .font(.headline)
                            Spacer()
                            NavigationLink(destination: MapView()) {
                                Text("View Full Map →")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Map(
                            coordinateRegion: .constant(
                                locationManager.currentLocation != nil ?
                                MKCoordinateRegion(
                                    center: locationManager.currentLocation!.coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                ) :
                                MKCoordinateRegion(
                                    center: CLLocationCoordinate2D(latitude: 22.30, longitude: 114.1694),
                                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                )
                            ),
                            showsUserLocation: locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways
                        )
                        .frame(height: 180)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)
                    
                    // 4. 新闻信息流
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Campus News")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        ForEach(staticNews) { news in
                            NewsCard(news: news)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 16)
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // 启动位置更新
                locationManager.startUpdatingLocation()
            }
        }
    }
}

// 图书馆快速访问卡片子视图
struct LibraryQuickAccessCard: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
            
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Library Services")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Find books, study rooms & more")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "book.fill")
                    .font(.title2)
                    .foregroundColor(.green)
            }
            .padding()
        }
        .frame(height: 80)
        .padding(.horizontal)
    }
}

// 新闻数据模型
struct NewsItem: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    let time: String
}

// 学术提醒卡片子视图
struct AcademicReminderCard: View {
    // 静态作业数量
    private var pendingHomeworksCount: Int {
        return 3 // 静态数据
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

// 新闻卡片子视图
struct NewsCard: View {
    let news: NewsItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(news.title)
                .font(.headline)
            Text(news.content)
                .font(.body)
                .foregroundColor(.secondary)
            Text(news.time)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(selectedTab: .constant(0))
    }
}
