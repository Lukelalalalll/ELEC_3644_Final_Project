import SwiftUI
import MapKit
import CoreLocation
import SwiftData
import FirebaseFirestore

enum Weekday: Int, CaseIterable {
    case sunday = 1, monday = 2, tuesday = 3, wednesday = 4, thursday = 5, friday = 6, saturday = 7
    
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
    let startTime: Date
    let endTime: Date
}

// 香港公众假期列表（2025年）
let hongKongHolidays = [
    "01-01", // New Year's Day
    "01-02", // Day following New Year's Day
    "02-10", // Lunar New Year's Day
    "02-11", // Lunar New Year's Day 2
    "02-12", // Lunar New Year's Day 3
    "03-29", // Good Friday
    "03-30", // Day following Good Friday
    "04-04", // Ching Ming Festival
    "04-01", // Easter Monday
    "05-01", // Labour Day
    "05-15", // Buddha's Birthday
    "06-10", // Tuen Ng Festival
    "07-01", // HKSAR Establishment Day
    "09-18", // Day following Mid-Autumn Festival
    "10-01", // National Day
    "10-11", // Chung Yeung Festival
    "12-25", // Christmas Day
    "12-26"  // First weekday after Christmas
]

struct HomeView: View {
    @Binding var selectedTab: Int
    @State private var locationManager = LocationManager.shared
    @State private var selectedDate = Date()
    @State private var currentPage = 0
    @State private var dragOffset: CGFloat = 0
    @State private var timer: Timer? = nil
    
    // 添加状态管理
    @State private var userCourses: [SimpleCourse] = []
    @State private var isLoading = false
    @State private var enrolledCourseIds: [String] = []
    
    // 获取当前用户ID
    private var currentUserId: String? {
        UserDefaults.standard.string(forKey: "currentUserId")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    NavigationLink(destination: LibraryView().navigationTitle("Library")) {
                        LibraryQuickAccessCard()
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Course Schedule")
                                .font(.headline)
                            
                            Spacer()
                            
                            // 添加刷新按钮
                            Button(action: {
                                loadUserCoursesFromFirebase()
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                            
                            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .onChange(of: selectedDate) { newDate in
                                    if let index = weekDates.firstIndex(where: { calendarDate in
                                        Calendar.current.isDate(calendarDate, inSameDayAs: newDate)
                                    }) {
                                        withAnimation(.spring()) {
                                            currentPage = index
                                        }
                                    }
                                    resetTimer()
                                }
                        }
                        .padding(.horizontal)
                        
                        GeometryReader { geometry in
                            let cardWidth = geometry.size.width - 60
                            let spacing = 15.0
                            let initialOffset = (geometry.size.width - cardWidth) / 2
                            
                            HStack(spacing: spacing) {
                                ForEach(0..<7, id: \.self) { index in
                                    let date = weekDates[index]
                                    let weekday = weekdayForDate(date)
                                    let dayCourses = coursesForDate(date)
                                    let isHoliday = isHoliday(date)
                                    let isToday = Calendar.current.isDate(date, inSameDayAs: Date())
                                    
                                    VStack(spacing: 12) {
                                        VStack(spacing: 4) {
                                            Text(formattedDate(date))
                                                .font(.headline)
                                                .bold()
                                            Text(weekday.name)
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                            
                                            if isHoliday {
                                                Text("Holiday")
                                                    .font(.caption)
                                                    .foregroundColor(.red)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 2)
                                                    .background(Color.red.opacity(0.1))
                                                    .cornerRadius(4)
                                            } else if isToday {
                                                Text("Today")
                                                    .font(.caption)
                                                    .foregroundColor(.blue)
                                                    .padding(.horizontal, 8)
                                                    .padding(.vertical, 2)
                                                    .background(Color.blue.opacity(0.1))
                                                    .cornerRadius(4)
                                            }
                                        }
                                        .padding(.top, 16)
                                        
                                        ScrollView {
                                            LazyVStack(spacing: 10) {
                                                if isHoliday {
                                                    Text("Public Holiday")
                                                        .font(.body)
                                                        .foregroundColor(.red)
                                                        .padding()
                                                } else if dayCourses.isEmpty {
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
                                        .frame(maxHeight: 300)
                                    }
                                    .frame(width: cardWidth, height: 360)
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
                                        let threshold: CGFloat = 50
                                        var newPage = currentPage
                                        
                                        if value.translation.width < -threshold {
                                            newPage = min(currentPage + 1, 6)
                                        } else if value.translation.width > threshold {
                                            newPage = max(currentPage - 1, 0)
                                        }
                                        
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            currentPage = newPage
                                            dragOffset = 0
                                            selectedDate = dateForPage(newPage)
                                        }
                                        resetTimer()
                                    }
                            )
                        }
                        .frame(height: 360)
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Campus Map")
                                .font(.headline)
                            Spacer()
                            NavigationLink(destination: CampusMapView()) {
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
                        .frame(height: 30)
                }
                .padding(.vertical, 16)
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                locationManager.startUpdatingLocation()
                // 修复：确保正确的初始页面
                currentPage = calculateTodayPage()
                selectedDate = Date()
                resetTimer()
                loadUserCoursesFromFirebase() // 首次加载时从Firebase加载课程
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
    }
    
    // MARK: - 数据加载方法
    
    // 从Firebase加载用户课程
    private func loadUserCoursesFromFirebase() {
        guard let userId = currentUserId else {
            print("❌ 没有当前用户ID")
            return
        }
        
        isLoading = true
        print("🔄 从Firebase加载用户课程，用户ID: \(userId)")
        
        FirebaseService.shared.fetchEnrolledCourseIds(for: userId) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let courseIds):
                    print("✅ 从Firebase获取到课程ID: \(courseIds)")
                    self.enrolledCourseIds = courseIds
                    self.fetchCourseDetailsFromFirebase(courseIds: courseIds)
                    
                case .failure(let error):
                    print("❌ 从Firebase加载课程失败: \(error.localizedDescription)")
                    self.userCourses = []
                }
            }
        }
    }
    
    private func fetchCourseDetailsFromFirebase(courseIds: [String]) {
        let db = Firestore.firestore()
        let group = DispatchGroup()
        var courses: [SimpleCourse] = []
        var errors: [Error] = []
        
        for courseId in courseIds {
            group.enter()
            
            db.collection("courses").document(courseId).getDocument { document, error in
                defer { group.leave() }
                
                if let error = error {
                    errors.append(error)
                    print("❌ 获取课程详情失败 \(courseId): \(error)")
                    return
                }
                
                guard let document = document, document.exists,
                      let data = document.data() else {
                    print("❌ 课程文档不存在: \(courseId)")
                    return
                }
                
                if let simpleCourse = self.convertToSimpleCourse(from: data, id: courseId) {
                    courses.append(contentsOf: simpleCourse)
                    print("✅ 成功加载课程: \(courseId)")
                } else {
                    print("❌ 转换课程失败: \(courseId)")
                }
            }
        }
        
        group.notify(queue: .main) {
            if !errors.isEmpty {
                print("⚠️ 部分课程加载失败: \(errors.count) 个错误")
            }
            
            self.userCourses = courses
            self.isLoading = false
            print("🎯 最终加载SimpleCourse数量: \(courses.count)")
        }
    }
    
    private func convertToSimpleCourse(from data: [String: Any], id: String) -> [SimpleCourse]? {
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
        
        var simpleCourses: [SimpleCourse] = []
        
        // 转换上课时间
        if let classTimes = data["classTimes"] as? [[String: Any]] {
            print("📅 找到 \(classTimes.count) 个上课时间段")
            for (index, classTimeData) in classTimes.enumerated() {
                print("🔍 处理第 \(index + 1) 个时间段: \(classTimeData)")
                
                // 处理 dayOfWeek：可能是 String 或 Int
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
                
                // 转换为 Calendar 的星期格式 (1=周日, 2=周一, ..., 7=周六)
                let calendarWeekday: Int
                switch dayOfWeek {
                case 1: calendarWeekday = 2 // 周一 -> 2
                case 2: calendarWeekday = 3 // 周二 -> 3
                case 3: calendarWeekday = 4 // 周三 -> 4
                case 4: calendarWeekday = 5 // 周四 -> 5
                case 5: calendarWeekday = 6 // 周五 -> 6
                case 6: calendarWeekday = 7 // 周六 -> 7
                case 7: calendarWeekday = 1 // 周日 -> 1
                default: calendarWeekday = dayOfWeek
                }
                
                let weekday = Weekday(rawValue: calendarWeekday)
                
                // 格式化时间显示
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm"
                let startTimeStr = timeFormatter.string(from: startTime)
                let endTimeStr = timeFormatter.string(from: endTime)
                
                // 修复：dayNames 数组索引与 calendarWeekday 对齐
                let dayNames = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                let dayName = dayNames.indices.contains(calendarWeekday) ? dayNames[calendarWeekday] : "Unknown"
                
                let simpleCourse = SimpleCourse(
                    courseId: id,
                    courseName: courseName,
                    professor: professor,
                    courseCode: courseCode,
                    credits: credits,
                    time: "\(dayName) \(startTimeStr)-\(endTimeStr)",
                    classroom: location.isEmpty ? "TBD" : location,
                    weekday: weekday,
                    startTime: startTime,
                    endTime: endTime
                )
                simpleCourses.append(simpleCourse)
                print("✅ 添加课程时间段: \(courseCode) - \(dayName) \(startTimeStr)-\(endTimeStr) (原始星期: \(dayOfWeek), 调整后: \(calendarWeekday))")
            }
        } else {
            print("❌ 没有找到 classTimes 字段或格式错误")
        }
        
        return simpleCourses
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
    
    // MARK: - 日期计算方法
    
    // 计算当前周的日期
    private var weekDates: [Date] {
        let calendar = Calendar.current
        let today = Date()
        // 修正：使用正确的周开始（周日开始）
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        return (0..<7).map { calendar.date(byAdding: .day, value: $0, to: startOfWeek)! }
    }
    
    // 修复：计算今天对应的页面索引
    func calculateTodayPage() -> Int {
        let calendar = Calendar.current
        let weekdayNum = calendar.component(.weekday, from: Date())
        // 修正：Calendar的weekday从1(周日)到7(周六)
        // 我们的页面索引应该是0(周日)到6(周六)
        // 直接返回 weekdayNum - 1 是正确的
        return weekdayNum - 1
    }
    
    // 根据页面索引获取对应的日期
    private func dateForPage(_ page: Int) -> Date {
        return weekDates[page]
    }
    
    // 格式化日期显示
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    // 获取星期几对应的Weekday枚举
    private func weekdayForDate(_ date: Date) -> Weekday {
        let calendar = Calendar.current
        let weekdayNum = calendar.component(.weekday, from: date)
        return Weekday(rawValue: weekdayNum) ?? .sunday
    }
    
    // 检查是否为假期
    private func isHoliday(_ date: Date) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd"
        let dateString = dateFormatter.string(from: date)
        return hongKongHolidays.contains(dateString)
    }
    
    // 按星期几分组课程
    private var coursesByWeekday: [Weekday: [SimpleCourse]] {
        var result: [Weekday: [SimpleCourse]] = [:]
        
        for course in userCourses {
            guard let weekday = course.weekday else { continue }
            if result[weekday] == nil {
                result[weekday] = []
            }
            result[weekday]?.append(course)
        }
        
        // 按开始时间排序
        for (weekday, courses) in result {
            result[weekday] = courses.sorted { $0.startTime < $1.startTime }
        }
        
        return result
    }
    
    // 获取指定日期的课程（如果是假期则返回空数组）
    private func coursesForDate(_ date: Date) -> [SimpleCourse] {
        if isHoliday(date) {
            return []
        }
        
        let weekday = weekdayForDate(date)
        return coursesByWeekday[weekday] ?? []
    }
    
    func resetTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
            withAnimation(.spring()) {
                currentPage = calculateTodayPage()
                selectedDate = Date()
                dragOffset = 0
            }
        }
    }
}

// 其他视图保持不变...
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

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(selectedTab: .constant(0))
    }
}
