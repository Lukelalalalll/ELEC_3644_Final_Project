import SwiftUI

struct LibraryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentTime = Date()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text(formattedCurrentDate())
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(formattedCurrentTimeWithSeconds())
                        .font(.system(.title2, design: .monospaced))
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .onAppear {
                            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                                currentTime = Date()
                            }
                        }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
                
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
        .padding(.bottom, 80)
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
    
    private func formattedCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: currentTime)
    }
    
    private func formattedCurrentTimeWithSeconds() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        formatter.dateStyle = .none
        return formatter.string(from: currentTime)
    }
}

struct Library {
    let name: String
    let weekdayHours: String
    let weekendHours: String
    let holidayHours: String
    let isAlwaysOpen: Bool
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
            ZStack {
                Circle()
                    .fill(isOpen ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Circle()
                    .fill(isOpen ? Color.green : Color.red)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                            .shadow(radius: 1)
                    )
                
                if isOpen {
                    Circle()
                        .stroke(Color.green, lineWidth: 2)
                        .frame(width: 32, height: 32)
                        .scaleEffect(1.2)
                        .opacity(0)
                        .animation(
                            Animation.easeInOut(duration: 2)
                                .repeatForever(autoreverses: false),
                            value: isOpen
                        )
                }
            }
            
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
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isOpen ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.15), radius: 3, x: 0, y: 2)
    }
}

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
    static let holidays: [String] = [
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
    
    static func isLibraryOpen(library: Library) -> Bool {
        let now = Date()
        let calendar = Calendar.current
        
        // Check if today is a holiday
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd"
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
        dateFormatter.dateFormat = "MM-dd"
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
        
        // Special handling for Chi Wah Learning Commons
        if library.name == "Chi Wah Learning Commons" {
            return isChiWahOpen()
        }
        
        let now = Date()
        let calendar = Calendar.current
        
        // Parse the hours string
        let components = hoursString.components(separatedBy: " - ")
        guard components.count == 2 else { return false }
        
        let openTimeString = components[0]
        let closeTimeString = components[1]
        
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
    
    private static func isChiWahOpen() -> Bool {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentTimeInMinutes = currentHour * 60 + currentMinute
        
        // Chi Wah Learning Commons hours: 08:00 - 06:00 next day
        // This means it's closed only from 06:00 to 08:00 (2 hours)
        // Open from 08:00 to 06:00 next day (22 hours)
        
        let openTimeInMinutes = 8 * 60  // 08:00 = 480 minutes
        let closeTimeInMinutes = 6 * 60 // 06:00 = 360 minutes
        
        if currentTimeInMinutes >= openTimeInMinutes {
            // After 08:00 on the same day - should be open
            return true
        } else if currentTimeInMinutes < closeTimeInMinutes {
            // Before 06:00 on the same day - this is actually from the previous day's opening
            // So it should be open (overnight)
            return true
        } else {
            // Between 06:00 and 08:00 - closed
            return false
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
