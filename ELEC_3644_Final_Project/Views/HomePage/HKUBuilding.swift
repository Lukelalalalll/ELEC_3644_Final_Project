import Foundation
import CoreLocation
import SwiftUI

struct HKUBuilding: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let description: String
    let iconName: String
    let color: Color
    
    static let allBuildings: [HKUBuilding] = [
        HKUBuilding(
            name: "Main Building",
            coordinate: CLLocationCoordinate2D(latitude: 22.2846, longitude: 114.13783),
            description: "HKU Main Building, historical architecture",
            iconName: "building.columns",
            color: .red
        ),
        HKUBuilding(
            name: "Main Library",
            coordinate: CLLocationCoordinate2D(latitude: 22.28343, longitude: 114.13778),
            description: "LE Lecture Rooms,Main Library",
            iconName: "books.vertical",
            color: .blue
        ),
        HKUBuilding(
            name: "Student Union",
            coordinate: CLLocationCoordinate2D(latitude: 22.35639, longitude: 114.25195),
            description: "SU Restaurant",
            iconName: "person.3",
            color: .green
        ),
        HKUBuilding(
            name: "MWT Meng Wah Building",
            coordinate: CLLocationCoordinate2D(latitude: 22.2822, longitude: 114.13918),
            description: "MWT Lecture Rooms",
            iconName: "sportscourt",
            color: .orange
        ),
        HKUBuilding(
            name: "CYCC 庄月明文化中心",
            coordinate: CLLocationCoordinate2D(latitude: 22.28268, longitude: 114.13906),
            description: "CYM Cultural Centre",
            iconName: "atom",
            color: .purple
        ),
        HKUBuilding(
            name: "HW Haking Wong Building",
            coordinate: CLLocationCoordinate2D(latitude: 22.28296, longitude: 114.13645),
            description: "Faculty of Engineering,Haking Wong Building",
            iconName: "gear",
            color: .brown
        ),
        HKUBuilding(
            name: "Chong Yuet Ming Chemistry Building",
            coordinate: CLLocationCoordinate2D(latitude: 22.28307, longitude: 114.13979),
            description: "CYCP Lecture Rooms",
            iconName: "testtube.2",
            color: .pink
        ),
        HKUBuilding(
            name: "Chong Yuet Ming Physics Building",
            coordinate: CLLocationCoordinate2D(latitude: 22.28328, longitude: 114.13979),
            description: "CYPP Lecture Rooms",
            iconName: "atom",
            color: .pink
        ),
        HKUBuilding(
            name: "Knowles Building",
            coordinate: CLLocationCoordinate2D(latitude: 22.28323, longitude: 114.13843),
            description: "KB Lecture Rooms",
            iconName: "building.2",
            color: .pink
        ),
        HKUBuilding(
            name: "K.K. Leung Building",
            coordinate: CLLocationCoordinate2D(latitude: 22.28327, longitude: 114.13902),
            description: "KB Lecture Rooms",
            iconName: "graduationcap",
            color: .pink
        ),
        HKUBuilding(
            name: "Chow Yei Ching Building",
            coordinate: CLLocationCoordinate2D(latitude: 22.28308, longitude: 114.13544),
            description: "CB Lecture Rooms",
            iconName: "briefcase",
            color: .pink
        ),
        HKUBuilding(
            name: "Run Run Shaw Tower",
            coordinate: CLLocationCoordinate2D(latitude: 22.28369, longitude: 114.13436),
            description: "RRS/CRT Rooms",
            iconName: "briefcase",
            color: .pink
        ),
        HKUBuilding(
            name: "HKU CPD 百週年",
            coordinate: CLLocationCoordinate2D(latitude: 22.283266, longitude: 114.133957),
            description: "CPD Rooms",
            iconName: "briefcase",
            color: .pink
        )
    ]
}
