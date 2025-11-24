//
//
//import SwiftUI
//import MapKit
//
//// MARK: - 星期枚举
//enum Weekday: Int, CaseIterable {
//    case monday = 2, tuesday = 3, wednesday = 4, thursday = 5, friday = 6, saturday = 7, sunday = 1
//    
//    var name: String {
//        switch self {
//        case .monday: return "Monday"
//        case .tuesday: return "Tuesday"
//        case .wednesday: return "Wednesday"
//        case .thursday: return "Thursday"
//        case .friday: return "Friday"
//        case .saturday: return "Saturday"
//        case .sunday: return "Sunday"
//        }
//    }
//}
//
//// MARK: - 简化课程数据结构（用于预览）
//struct SimpleCourse: Identifiable {
//    let id = UUID()
//    let courseId: String
//    let courseName: String
//    let professor: String
//    let courseCode: String
//    let credits: Int
//    let time: String
//    let classroom: String
//    let weekday: Weekday?
//}
//
//// MARK: - 示例数据
//let sampleCourses: [SimpleCourse] = [
//    SimpleCourse(
//        courseId: "ELEC3644",
//        courseName: "Digital System Design",
//        professor: "Prof. Zhang",
//        courseCode: "ELEC3644",
//        credits: 4,
//        time: "Mon 9:00-10:30",
//        classroom: "Engineering Building 301",
//        weekday: .monday
//    ),
//    SimpleCourse(
//        courseId: "COMP2119",
//        courseName: "Data Structures",
//        professor: "Prof. Li",
//        courseCode: "COMP2119",
//        credits: 4,
//        time: "Tue 10:00-11:30",
//        classroom: "CS Building 201",
//        weekday: .tuesday
//    ),
//    SimpleCourse(
//        courseId: "COMP3230",
//        courseName: "Computer Architecture",
//        professor: "Prof. Wang",
//        courseCode: "COMP3230",
//        credits: 3,
//        time: "Mon 13:00-14:30",
//        classroom: "CS Building 305",
//        weekday: .monday
//    ),
//    SimpleCourse(
//        courseId: "MATH1853",
//        courseName: "Linear Algebra",
//        professor: "Prof. Chen",
//        courseCode: "MATH1853",
//        credits: 3,
//        time: "Wed 14:00-15:30",
//        classroom: "Math Building 101",
//        weekday: .wednesday
//    )
//]
//
//struct HomeView: View {
//    @Binding var selectedTab: Int
//    @State private var selectedDate = Date()
//    @State private var currentPage = 0
//    @State private var dragOffset: CGFloat = 0
//    @State private var timer: Timer? = nil
//    
//    private var weekDates: [Date] {
//        let calendar = Calendar.current
//        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate))!
//        return (0..<7).map { calendar.date(byAdding: .day, value: $0, to: startOfWeek)! }
//    }
//    
//    private var coursesByWeekday: [Weekday: [SimpleCourse]] {
//        var result: [Weekday: [SimpleCourse]] = [:]
//        
//        for course in sampleCourses {
//            guard let weekday = course.weekday else { continue }
//            if result[weekday] == nil {
//                result[weekday] = []
//            }
//            result[weekday]?.append(course)
//        }
//        
//        return result
//    }
//    
//    func resetTimer() {
//        timer?.invalidate()
//        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
//            withAnimation(.spring()) {
//                currentPage = calculateTodayPage()
//                dragOffset = 0
//            }
//        }
//    }
//    
//    func calculateTodayPage() -> Int {
//        let weekdayNum = Calendar.current.component(.weekday, from: Date())
//        return (weekdayNum == 1 ? 6 : weekdayNum - 2)
//    }
//
//    var body: some View {
//        NavigationStack {
//            ScrollView {
//                VStack(spacing: 20) {
//                    // 1. 学术提醒卡片
//                    AcademicReminderCard()
//                        .onTapGesture {
//                            selectedTab = 3
//                        }
//                    
//                    // 2. 图书馆快速访问按钮
//                    NavigationLink(destination: Text("Library View").navigationTitle("Library")) {
//                        LibraryQuickAccessCard()
//                    }
//                    .buttonStyle(PlainButtonStyle())
//                    
//                    // 3. 课程表模块
//                    VStack(alignment: .leading, spacing: 16) {
//                        HStack {
//                            Text("Course Schedule")
//                                .font(.headline)
//                            Spacer()
//                            
//                            DatePicker("", selection: $selectedDate, displayedComponents: .date)
//                                .datePickerStyle(.compact)
//                                .labelsHidden()
//                        }
//                        .padding(.horizontal)
//                        
//                        // 滑动课程卡片区域
//                        GeometryReader { geometry in
//                            let cardWidth = geometry.size.width - 60
//                            let spacing = 15.0
//                            let initialOffset = (geometry.size.width - cardWidth) / 2
//                            
//                            HStack(spacing: spacing) {
//                                ForEach(0..<7, id: \.self) { index in
//                                    let date = weekDates[index]
//                                    let weekday = Weekday.allCases[index]
//                                    let dayCourses = coursesByWeekday[weekday] ?? []
//                                    
//                                    VStack(spacing: 12) {
//                                        Text(date, style: .date)
//                                            .font(.headline)
//                                            .bold()
//                                            .padding(.top, 16)
//                                        
//                                        Text(weekday.name)
//                                            .font(.subheadline)
//                                            .foregroundColor(.secondary)
//                                        
//                                        ScrollView {
//                                            LazyVStack(spacing: 8) {
//                                                if dayCourses.isEmpty {
//                                                    Text("No courses today")
//                                                        .font(.caption)
//                                                        .foregroundColor(.secondary)
//                                                        .padding()
//                                                } else {
//                                                    ForEach(dayCourses) { course in
//                                                        NavigationLink {
//                                                            SimpleCourseDetailView(course: course)
//                                                        } label: {
//                                                            CompactCourseRowView(course: course)
//                                                        }
//                                                        .buttonStyle(.plain)
//                                                    }
//                                                }
//                                            }
//                                            .padding(.horizontal, 8)
//                                        }
//                                        .frame(maxHeight: 120)
//                                    }
//                                    .frame(width: cardWidth)
//                                    .background(
//                                        RoundedRectangle(cornerRadius: 16)
//                                            .fill(Color(.systemBackground))
//                                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
//                                    )
//                                    .scaleEffect(currentPage == index ? 1.02 : 0.95)
//                                    .zIndex(currentPage == index ? 1 : 0)
//                                }
//                            }
//                            .offset(x: initialOffset - CGFloat(currentPage) * (cardWidth + spacing) + dragOffset)
//                            .gesture(
//                                DragGesture(minimumDistance: 10)
//                                    .onChanged { value in
//                                        dragOffset = value.translation.width
//                                        resetTimer()
//                                    }
//                                    .onEnded { value in
//                                        let predicted = value.predictedEndTranslation.width
//                                        let pageChange = Int(-predicted / (cardWidth + spacing))
//                                        let newPage = min(max(currentPage + pageChange, 0), 6)
//                                        
//                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
//                                            currentPage = newPage
//                                            dragOffset = 0
//                                        }
//                                        resetTimer()
//                                    }
//                            )
//                        }
//                        .frame(height: 220)
//                    }
//                    .padding(.horizontal)
//                    
//                    // 4. 简化地图预览模块
//                    VStack(alignment: .leading, spacing: 10) {
//                        HStack {
//                            Text("Campus Map")
//                                .font(.headline)
//                            Spacer()
//                            NavigationLink(destination: Text("Map View").navigationTitle("Campus Map")) {
//                                Text("View Full Map →")
//                                    .font(.subheadline)
//                                    .foregroundColor(.blue)
//                            }
//                        }
//                        
//                        // 简化地图预览 - 使用静态图片或简单矩形作为占位符
//                        Rectangle()
//                            .fill(Color.blue.opacity(0.1))
//                            .frame(height: 150)
//                            .cornerRadius(12)
//                            .overlay(
//                                VStack {
//                                    Image(systemName: "map")
//                                        .font(.largeTitle)
//                                        .foregroundColor(.blue)
//                                    Text("Campus Map")
//                                        .font(.headline)
//                                        .foregroundColor(.primary)
//                                }
//                            )
//                            .overlay(
//                                RoundedRectangle(cornerRadius: 12)
//                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
//                            )
//                    }
//                    .padding(.horizontal)
//                }
//                .padding(.vertical, 16)
//            }
//            .navigationTitle("Home")
//            .navigationBarTitleDisplayMode(.inline)
//            .onAppear {
//                currentPage = calculateTodayPage()
//            }
//            .onChange(of: selectedDate) { _ in
//                let weekdayNum = Calendar.current.component(.weekday, from: selectedDate)
//                currentPage = (weekdayNum == 1 ? 6 : weekdayNum - 2)
//                resetTimer()
//            }
//        }
//    }
//}
//
//// MARK: - 简单课程详情视图（替代 CourseScheduleView）
//struct SimpleCourseDetailView: View {
//    let course: SimpleCourse
//    
//    var body: some View {
//        VStack(spacing: 20) {
//            VStack(spacing: 12) {
//                Text(course.courseCode)
//                    .font(.title)
//                    .bold()
//                Text(course.courseName)
//                    .font(.headline)
//                    .foregroundColor(.secondary)
//            }
//            .padding()
//            
//            List {
//                Section("Course Information") {
//                    InfoRow(title: "Professor", value: course.professor)
//                    InfoRow(title: "Credits", value: "\(course.credits)")
//                    InfoRow(title: "Time", value: course.time)
//                    InfoRow(title: "Location", value: course.classroom)
//                }
//            }
//        }
//        .navigationTitle("Course Details")
//    }
//}
//
//struct InfoRow: View {
//    let title: String
//    let value: String
//    
//    var body: some View {
//        HStack {
//            Text(title)
//                .foregroundColor(.secondary)
//            Spacer()
//            Text(value)
//                .bold()
//        }
//    }
//}
//
//// 紧凑版课程行视图
//struct CompactCourseRowView: View {
//    let course: SimpleCourse
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 4) {
//            Text(course.courseCode)
//                .font(.system(size: 12, weight: .semibold))
//                .foregroundColor(.primary)
//            Text(course.time)
//                .font(.system(size: 10))
//                .foregroundColor(.blue)
//            Text(course.classroom)
//                .font(.system(size: 9))
//                .foregroundColor(.secondary)
//        }
//        .padding(8)
//        .frame(maxWidth: .infinity, alignment: .leading)
//        .background(
//            RoundedRectangle(cornerRadius: 8)
//                .fill(Color(.secondarySystemBackground))
//        )
//    }
//}
//
//// 图书馆快速访问卡片子视图
//struct LibraryQuickAccessCard: View {
//    var body: some View {
//        ZStack {
//            RoundedRectangle(cornerRadius: 12)
//                .fill(Color.green.opacity(0.1))
//                .overlay(
//                    RoundedRectangle(cornerRadius: 12)
//                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
//                )
//            
//            HStack {
//                VStack(alignment: .leading, spacing: 6) {
//                    Text("Library Services")
//                        .font(.headline)
//                        .foregroundColor(.primary)
//                    Text("Find books, study rooms & more")
//                        .font(.subheadline)
//                        .foregroundColor(.secondary)
//                }
//                
//                Spacer()
//                
//                Image(systemName: "book.fill")
//                    .font(.title2)
//                    .foregroundColor(.green)
//            }
//            .padding()
//        }
//        .frame(height: 80)
//        .padding(.horizontal)
//    }
//}
//
//// 学术提醒卡片子视图
//struct AcademicReminderCard: View {
//    // 静态作业数量
//    private var pendingHomeworksCount: Int {
//        return 3 // 静态数据
//    }
//    
//    var body: some View {
//        ZStack {
//            RoundedRectangle(cornerRadius: 12)
//                .fill(Color.blue.opacity(0.1))
//            VStack(alignment: .leading, spacing: 8) {
//                Text("Academic Deadlines")
//                    .font(.headline)
//                Text("\(pendingHomeworksCount) assignments due this week")
//                    .font(.subheadline)
//            }
//            .padding()
//        }
//        .frame(height: 100)
//        .padding(.horizontal)
//    }
//}
//
//struct HomeView_Previews: PreviewProvider {
//    static var previews: some View {
//        HomeView(selectedTab: .constant(0))
//    }
//}



import SwiftUI
import MapKit
import CoreLocation

// MARK: - 星期枚举
enum Weekday: Int, CaseIterable {
    case monday = 2, tuesday = 3, wednesday = 4, thursday = 5, friday = 6, saturday = 7, sunday = 1
    
    var name: String {
        switch self {
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        case .sunday: return "Sunday"
        }
    }
}

// MARK: - 简化课程数据结构（用于预览）
struct SimpleCourse: Identifiable {
    let id = UUID()
    let courseId: String
    let courseName: String
    let professor: String
    let courseCode: String
    let credits: Int
    let time: String
    let classroom: String
    let weekday: Weekday?
}

// MARK: - 示例数据
let sampleCourses: [SimpleCourse] = [
    SimpleCourse(
        courseId: "ELEC3644",
        courseName: "Digital System Design",
        professor: "Prof. Zhang",
        courseCode: "ELEC3644",
        credits: 4,
        time: "Mon 9:00-10:30",
        classroom: "Engineering Building 301",
        weekday: .monday
    ),
    SimpleCourse(
        courseId: "COMP2119",
        courseName: "Data Structures and Algorithms",
        professor: "Prof. Li",
        courseCode: "COMP2119",
        credits: 4,
        time: "Tue 10:00-11:30",
        classroom: "Computer Science Building 201",
        weekday: .tuesday
    ),
    SimpleCourse(
        courseId: "COMP3230",
        courseName: "Computer Architecture",
        professor: "Prof. Wang",
        courseCode: "COMP3230",
        credits: 3,
        time: "Mon 13:00-14:30",
        classroom: "Computer Science Building 305",
        weekday: .monday
    ),
    SimpleCourse(
        courseId: "MATH1853",
        courseName: "Linear Algebra",
        professor: "Prof. Chen",
        courseCode: "MATH1853",
        credits: 3,
        time: "Wed 14:00-15:30",
        classroom: "Mathematics Building 101",
        weekday: .wednesday
    ),
    SimpleCourse(
        courseId: "ELEC3848",
        courseName: "Integrated Design Project",
        professor: "Prof. Liu",
        courseCode: "ELEC3848",
        credits: 4,
        time: "Wed 9:00-12:00",
        classroom: "Engineering Lab 401",
        weekday: .wednesday
    )
]

struct HomeView: View {
    @Binding var selectedTab: Int
    @State private var locationManager = LocationManager()
    @State private var selectedDate = Date()
    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0
    @State private var timer: Timer? = nil
    
    private var weekDates: [Date] {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedDate))!
        return (0..<7).map { calendar.date(byAdding: .day, value: $0, to: startOfWeek)! }
    }
    
    private var coursesByWeekday: [Weekday: [SimpleCourse]] {
        var result: [Weekday: [SimpleCourse]] = [:]
        
        for course in sampleCourses {
            guard let weekday = course.weekday else { continue }
            if result[weekday] == nil {
                result[weekday] = []
            }
            result[weekday]?.append(course)
        }
        
        return result
    }
    
    func resetTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
            withAnimation(.spring()) {
                currentPage = calculateTodayPage()
                dragOffset = 0
            }
        }
    }
    
    func calculateTodayPage() -> Int {
        let weekdayNum = Calendar.current.component(.weekday, from: Date())
        return (weekdayNum == 1 ? 6 : weekdayNum - 2)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
//                    // 1. 学术提醒卡片
//                    AcademicReminderCard()
//                        .onTapGesture {
//                            selectedTab = 3
//                        }
                    
                    // 2. 图书馆快速访问按钮
                    NavigationLink(destination: LibraryView().navigationTitle("Library")) {
                        LibraryQuickAccessCard()
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // 3. 课程表模块
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Course Schedule")
                                .font(.headline)
                            Spacer()
                            
                            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                        }
                        .padding(.horizontal)
                        
                        // 滑动课程卡片区域 - 增加高度
                        GeometryReader { geometry in
                            let cardWidth = geometry.size.width - 60
                            let spacing = 15.0
                            let initialOffset = (geometry.size.width - cardWidth) / 2
                            
                            HStack(spacing: spacing) {
                                ForEach(0..<7, id: \.self) { index in
                                    let date = weekDates[index]
                                    let weekday = Weekday.allCases[index]
                                    let dayCourses = coursesByWeekday[weekday] ?? []
                                    
                                    VStack(spacing: 12) {
                                        // 日期和星期信息
                                        VStack(spacing: 4) {
                                            Text(date, style: .date)
                                                .font(.headline)
                                                .bold()
                                            Text(weekday.name)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.top, 16)
                                        
                                        // 课程列表 - 增加最大高度
                                        ScrollView {
                                            LazyVStack(spacing: 10) {
                                                if dayCourses.isEmpty {
                                                    Text("No courses today")
                                                        .font(.body)
                                                        .foregroundColor(.secondary)
                                                        .padding()
                                                } else {
                                                    ForEach(dayCourses) { course in
                                                        NavigationLink {
                                                            SimpleCourseDetailView(course: course)
                                                        } label: {
                                                            CompactCourseRowView(course: course)
                                                        }
                                                        .buttonStyle(.plain)
                                                    }
                                                }
                                            }
                                            .padding(.horizontal, 8)
                                        }
                                        .frame(maxHeight: 300) // 增加滚动区域高度
                                    }
                                    .frame(width: cardWidth, height: 320) // 增加卡片总高度
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color(.systemBackground))
                                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                    )
                                    .scaleEffect(currentPage == index ? 1.02 : 0.95)
                                    .zIndex(currentPage == index ? 1 : 0)
                                }
                            }
                            .offset(x: initialOffset - CGFloat(currentPage) * (cardWidth + spacing) + dragOffset)
                            .gesture(
                                DragGesture(minimumDistance: 10)
                                    .onChanged { value in
                                        dragOffset = value.translation.width
                                        resetTimer()
                                    }
                                    .onEnded { value in
                                        let predicted = value.predictedEndTranslation.width
                                        let pageChange = Int(-predicted / (cardWidth + spacing))
                                        let newPage = min(max(currentPage + pageChange, 0), 6)
                                        
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            currentPage = newPage
                                            dragOffset = 0
                                        }
                                        resetTimer()
                                    }
                            )
                        }
                        .frame(height: 320) // 增加容器高度
                    }
                    .padding(.horizontal)
                    
                    // 4. 地图预览模块 - 恢复原来的地图功能
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
                    Spacer()
                        .frame(height: 30) // 可以调整这个高度来控制底部空间的大小
                }
                .padding(.vertical, 16)
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // 启动位置更新
                locationManager.startUpdatingLocation()
                currentPage = calculateTodayPage()
            }
            .onChange(of: selectedDate) { _ in
                let weekdayNum = Calendar.current.component(.weekday, from: selectedDate)
                currentPage = (weekdayNum == 1 ? 6 : weekdayNum - 2)
                resetTimer()
            }
        }
    }
}

// MARK: - 简单课程详情视图（替代 CourseScheduleView）
struct SimpleCourseDetailView: View {
    let course: SimpleCourse
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Text(course.courseCode)
                    .font(.title)
                    .bold()
                Text(course.courseName)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            List {
                Section("Course Information") {
                    InfoRow(title: "Professor", value: course.professor)
                    InfoRow(title: "Credits", value: "\(course.credits)")
                    InfoRow(title: "Time", value: course.time)
                    InfoRow(title: "Location", value: course.classroom)
                }
            }
        }
        .navigationTitle("Course Details")
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .bold()
        }
    }
}

// 紧凑版课程行视图 - 稍微增加内边距
struct CompactCourseRowView: View {
    let course: SimpleCourse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(course.courseCode)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
            Text(course.courseName)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .lineLimit(1)
            Text(course.time)
                .font(.system(size: 11))
                .foregroundColor(.blue)
            Text(course.classroom)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemBackground))
        )
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
//
//// 学术提醒卡片子视图
//struct AcademicReminderCard: View {
//    // 静态作业数量
//    private var pendingHomeworksCount: Int {
//        return 3 // 静态数据
//    }
//    
//    var body: some View {
//        ZStack {
//            RoundedRectangle(cornerRadius: 12)
//                .fill(Color.blue.opacity(0.1))
//            VStack(alignment: .leading, spacing: 8) {
//                Text("Academic Deadlines")
//                    .font(.headline)
//                Text("\(pendingHomeworksCount) assignments due this week")
//                    .font(.subheadline)
//            }
//            .padding()
//        }
//        .frame(height: 100)
//        .padding(.horizontal)
//    }
//}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(selectedTab: .constant(0))
    }
}
