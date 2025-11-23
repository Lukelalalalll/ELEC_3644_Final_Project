import Foundation
import MapKit
import CoreLocation
import SwiftData

// 地图标注模型（用于MapKit地图标注）
struct CampusAnnotation: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
}

// 首页动态模型（用于首页信息流展示）
struct HomePost: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    let time: String
}

// 截止日期模型（用于个人页展示作业截止信息）
struct Deadline: Identifiable {
    var id = UUID()
    let course: String
    let task: String
    let date: String
    
    // 可选：从Homework模型初始化的便捷构造方法
    init(from homework: Homework) {
        self.id = UUID()
        self.course = homework.course?.courseName ?? "Unknown Course"
        self.task = homework.title
        self.date = DateFormatter.localizedString(
            from: homework.dueDate,
            dateStyle: .medium,
            timeStyle: .none
        )
    }
}

// 日期格式化工具（全局可用）
enum DateFormatters {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let relativeTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.doesRelativeDateFormatting = true
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}
