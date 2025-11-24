import SwiftUI

struct LibraryView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Library Hours")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                
                LazyVStack(spacing: 12) {
                    ForEach(libraryData, id: \.name) { library in
                        LibraryRow(library: library)
                    }
                }
                
                Text("Note: Hours may change during holidays and special events")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
            .padding()
        }
        .padding(.bottom, 80) // 添加这行来避免被底部 TabBar 遮挡
        .navigationTitle("Library Services")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Home")
                    }
                }
            }
        }
    }
    
    private func formattedCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: Date())
    }
}

struct Library {
    let name: String
    let weekdayHours: String
    let weekendHours: String
    let holidayHours: String
    let isAlwaysOpen: Bool // For libraries that are always open on holidays (Music Library and Chi Wah Learning Commons)
}

struct LibraryRow: View {
    let library: Library
    
    private var isOpen: Bool {
        return LibraryScheduleManager.isLibraryOpen(library: library)
    }
    
    private var currentHours: String {
        return LibraryScheduleManager.getCurrentHours(library: library)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Status indicator - 增大圆点尺寸到20x20
            Circle()
                .fill(isOpen ? Color.green : Color.red)
                .frame(width: 20, height: 20)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                        .shadow(radius: 1)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(library.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(currentHours)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(isOpen ? "Open" : "Closed")
                .font(.subheadline)
                .foregroundColor(isOpen ? .green : .red)
                .fontWeight(.medium)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
    }
}

// Library data - 更新Tin Ka Ping Education Library的工作日时间
let libraryData: [Library] = [
    Library(name: "Main Library", weekdayHours: "8:30am - 10:00pm", weekendHours: "9:00am - 5:00pm", holidayHours: "Closed", isAlwaysOpen: false),
    Library(name: "Fung Ping Shan Library", weekdayHours: "8:30am - 10:00pm", weekendHours: "9:00am - 5:00pm", holidayHours: "Closed", isAlwaysOpen: false),
    Library(name: "Ko Wong Wai Ching Wendy Fine Arts Digital Library", weekdayHours: "8:30am - 10:00pm", weekendHours: "9:00am - 5:00pm", holidayHours: "Closed", isAlwaysOpen: false),
    Library(name: "Dental Library", weekdayHours: "9:00am - 9:00pm", weekendHours: "9:00am - 5:00pm", holidayHours: "Closed", isAlwaysOpen: false),
    Library(name: "Lui Che Woo Law Library", weekdayHours: "9:00am - 9:00pm", weekendHours: "9:00am - 5:00pm", holidayHours: "Closed", isAlwaysOpen: false),
    Library(name: "Yu Chun Keung Medical Library", weekdayHours: "9:00am - 9:00pm", weekendHours: "9:00am - 5:00pm", holidayHours: "Closed", isAlwaysOpen: false),
    Library(name: "Music Library", weekdayHours: "8:00am - 11:00pm", weekendHours: "8:00am - 11:00pm", holidayHours: "8:00am - 11:00pm", isAlwaysOpen: true),
    Library(name: "Chi Wah Learning Commons", weekdayHours: "08:00 – 06:00 next day", weekendHours: "08:00 – 06:00 next day", holidayHours: "08:00 – 06:00 next day", isAlwaysOpen: true),
    Library(name: "Tin Ka Ping Education Library", weekdayHours: "8:30am - 10:00pm", weekendHours: "9:00am - 5:00pm", holidayHours: "Closed", isAlwaysOpen: false)
]

// Schedule manager to handle opening hours logic
struct LibraryScheduleManager {
    // Holiday dates for 2024 (converted from the provided dates)
    static let holidays: [String] = [
        "2024-01-01", // New Year's Day
        "2024-02-10", // Lunar New Year's Day
        "2024-02-11", // Lunar New Year's Day 2
        "2024-02-12", // Lunar New Year's Day 3
        "2024-03-29", // Good Friday
        "2024-03-30", // Day following Good Friday
        "2024-04-04", // Ching Ming Festival
        "2024-04-01", // Easter Monday
        "2024-05-01", // Labour Day
        "2024-05-15", // Buddha's Birthday
        "2024-06-10", // Tuen Ng Festival
        "2024-07-01", // HKSAR Establishment Day
        "2024-09-18", // Day following Mid-Autumn Festival
        "2024-10-01", // National Day
        "2024-10-11", // Chung Yeung Festival
        "2024-12-25", // Christmas Day
        "2024-12-26"  // First weekday after Christmas
    ]
    
    static func isLibraryOpen(library: Library) -> Bool {
        let now = Date()
        let calendar = Calendar.current
        
        // Check if today is a holiday
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayString = dateFormatter.string(from: now)
        
        let isHoliday = holidays.contains(todayString)
        
        if isHoliday {
            // Special handling for libraries that are always open on holidays
            if library.isAlwaysOpen {
                return isWithinOperatingHours(library.holidayHours, library: library)
            } else {
                return false // Most libraries are closed on holidays
            }
        }
        
        // Check if it's weekend
        let isWeekend = calendar.isDateInWeekend(now)
        
        if isWeekend {
            return isWithinOperatingHours(library.weekendHours, library: library)
        } else {
            return isWithinOperatingHours(library.weekdayHours, library: library)
        }
    }
    
    static func getCurrentHours(library: Library) -> String {
        let now = Date()
        let calendar = Calendar.current
        
        // Check if today is a holiday
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayString = dateFormatter.string(from: now)
        
        let isHoliday = holidays.contains(todayString)
        
        if isHoliday {
            return library.holidayHours
        }
        
        // Check if it's weekend
        let isWeekend = calendar.isDateInWeekend(now)
        
        return isWeekend ? library.weekendHours : library.weekdayHours
    }
    
    private static func isWithinOperatingHours(_ hoursString: String, library: Library) -> Bool {
        guard hoursString != "Closed" else { return false }
        
        let now = Date()
        let calendar = Calendar.current
        
        // Parse the hours string
        let components = hoursString.components(separatedBy: " - ")
        guard components.count == 2 else { return false }
        
        let openTimeString = components[0]
        let closeTimeString = components[1]
        
        // Handle special case for Chi Wah Learning Commons (overnight)
        if library.name == "Chi Wah Learning Commons" {
            return isWithinOvernightHours(openTime: openTimeString, closeTime: closeTimeString)
        }
        
        // Parse open and close times
        guard let openTime = parseTime(openTimeString),
              let closeTime = parseTime(closeTimeString) else {
            return false
        }
        
        // Get current time components
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentTimeInMinutes = currentHour * 60 + currentMinute
        
        // Convert open and close times to minutes since midnight
        let openTimeInMinutes = openTime.hour * 60 + openTime.minute
        let closeTimeInMinutes = closeTime.hour * 60 + closeTime.minute
        
        return currentTimeInMinutes >= openTimeInMinutes && currentTimeInMinutes <= closeTimeInMinutes
    }
    
    private static func isWithinOvernightHours(openTime: String, closeTime: String) -> Bool {
        let now = Date()
        let calendar = Calendar.current
        
        guard let openTime = parseTime(openTime),
              let closeTime = parseTime(closeTime) else {
            return false
        }
        
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentTimeInMinutes = currentHour * 60 + currentMinute
        
        let openTimeInMinutes = openTime.hour * 60 + openTime.minute
        let closeTimeInMinutes = closeTime.hour * 60 + closeTime.minute
        
        // For overnight hours (close time is next day)
        if closeTimeInMinutes < openTimeInMinutes {
            // Current time is after open time (same day) OR before close time (next day)
            return currentTimeInMinutes >= openTimeInMinutes || currentTimeInMinutes <= closeTimeInMinutes
        } else {
            // Normal operating hours
            return currentTimeInMinutes >= openTimeInMinutes && currentTimeInMinutes <= closeTimeInMinutes
        }
    }
    
    private static func parseTime(_ timeString: String) -> (hour: Int, minute: Int)? {
        let trimmedString = timeString.replacingOccurrences(of: " ", with: "").lowercased()
        
        // Handle different time formats
        if trimmedString.contains("am") || trimmedString.contains("pm") {
            return parse12HourTime(trimmedString)
        } else {
            return parse24HourTime(trimmedString)
        }
    }
    
    private static func parse12HourTime(_ timeString: String) -> (hour: Int, minute: Int)? {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        
        if let date = formatter.date(from: timeString) {
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: date)
            let minute = calendar.component(.minute, from: date)
            return (hour, minute)
        }
        
        // Try alternative format without colon
        let alternativeFormatter = DateFormatter()
        alternativeFormatter.dateFormat = "ha"
        
        if let date = alternativeFormatter.date(from: timeString) {
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: date)
            return (hour, 0)
        }
        
        return nil
    }
    
    private static func parse24HourTime(_ timeString: String) -> (hour: Int, minute: Int)? {
        let components = timeString.components(separatedBy: ":")
        guard components.count >= 1 else {
            return nil
        }
        
        var hourString = components[0]
        var minuteString = "0"
        
        if components.count >= 2 {
            minuteString = components[1]
        }
        
        // Handle case where hour might have non-digit characters
        hourString = hourString.filter { $0.isNumber }
        minuteString = minuteString.filter { $0.isNumber }
        
        guard let hour = Int(hourString),
              let minute = Int(minuteString) else {
            return nil
        }
        
        return (hour, minute)
    }
}

struct LibraryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            LibraryView()
        }
    }
}
