//
//  MapView.swift
//  ELEC_3644_Final_Project
//
//
//import SwiftUI
//import MapKit
//import CoreLocation
//
//struct MapView: View {
//    @State private var locationManager = LocationManager()
//    @State private var searchText = ""
//    @State private var destination: MKMapItem?
//    @State private var selectedItem: MKMapItem?
//    @State private var route: MKRoute?
//    @State private var showLookAround = false
//    @State private var lookAroundScene: MKLookAroundScene?
//    @State private var isSearching = false
//
//    @State private var cameraPosition: MapCameraPosition = .automatic
//
//    var body: some View {
//        VStack {
//            HStack {
//                TextField("Input Destination Name（Such as：Festival Walk）", text: $searchText)
//                    .textFieldStyle(RoundedBorderTextFieldStyle())
//                    .onSubmit {
//                        geocodeDestination()
//                    }
//                
//                if !searchText.isEmpty {
//                    Button("Cancel") {
//                        searchText = ""
//                        resetAll()
//                    }
//                }
//            }
//            .padding(.horizontal)
//
//            Map(position: $cameraPosition, selection: $selectedItem) {
//                if let userLocation = locationManager.currentLocation?.coordinate {
//                    Annotation("My location", coordinate: userLocation) {
//                        ZStack {
//                            Circle()
//                                .fill(.blue.opacity(0.8))
//                                .frame(width: 20, height: 20)
//                            Circle()
//                                .stroke(.white, lineWidth: 2)
//                                .frame(width: 24, height: 24)
//                        }
//                    }
//                }
//
//                
//                if let destination = destination {
//                    Marker(
//                        destination.name ?? "Destination",
//                        systemImage: "mappin.circle.fill",
//                        coordinate: destination.placemark.coordinate
//                    )
//                    .tint(.red)
//                }
//
//                if let route = route {
//                    MapPolyline(route.polyline)
//                        .stroke(.blue, lineWidth: 6)
//                }
//            }
//            .mapStyle(.standard)
//            .mapControls {
//                MapUserLocationButton()
//                MapCompass()
//                MapScaleView()
//            }
//            .onChange(of: selectedItem) { oldValue, newValue in
//                handleSelection(newValue)
//            }
//        }
//        .safeAreaInset(edge: .bottom) {
//            VStack(spacing: 0) {
//                // Look Around 预览
//                if showLookAround, let scene = lookAroundScene {
//                    LookAroundPreview(initialScene: scene)
//                        .frame(height: 200)
//                        .cornerRadius(12)
//                        .padding()
//                }
//                
//                
//                if destination != nil {
//                    Button("Display Drive Route") {
//                        calculateDrivingRoute()
//                    }
//                    .buttonStyle(.borderedProminent)
//                    .padding()
//                }
//            }
//        }
//        .onAppear {
//                    locationManager.startUpdatingLocation()
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                        if locationManager.currentLocation == nil {
//                            let hku = CLLocation(latitude: 22.283, longitude: 114.137)
//                            locationManager.currentLocation = hku
//                        }
//                        updateCameraToUserLocation()
//                    }
//                }
//        .onChange(of: locationManager.currentLocation) { oldValue, newValue in
//            if destination == nil {
//                updateCameraToUserLocation()
//            }
//        }
//    }
//
//    private func geocodeDestination() {
//        guard !searchText.isEmpty else { return }
//        
//        let request = MKLocalSearch.Request()
//        request.naturalLanguageQuery = searchText
//        request.region = MKCoordinateRegion(
//            center: locationManager.currentLocation?.coordinate ??
//                   CLLocationCoordinate2D(latitude: 22.283, longitude: 114.137),
//            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
//        )
//
//        let search = MKLocalSearch(request: request)
//        search.start { response, error in
//            if let error = error {
//                print("Search Error: \(error.localizedDescription)")
//                return
//            }
//            
//            guard let mapItem = response?.mapItems.first else {
//                print("Result not find")
//                return
//            }
//            
//            self.destination = mapItem
//            self.selectedItem = mapItem
//            
//            if let userLocation = locationManager.currentLocation?.coordinate {
//                let coordinates = [userLocation, mapItem.placemark.coordinate]
//                self.cameraPosition = .rect(calculateMapRect(for: coordinates))
//            } else {
//                self.cameraPosition = .item(mapItem)
//            }
//        }
//    }
//
//    private func handleSelection(_ item: MKMapItem?) {
//        if let item = item {
//            Task {
//                let request = MKLookAroundSceneRequest(mapItem: item)
//                if let scene = try? await request.scene {
//                    self.lookAroundScene = scene
//                    self.showLookAround = true
//                } else {
//                    self.lookAroundScene = nil
//                    self.showLookAround = true
//                }
//            }
//        } else {
//            self.showLookAround = false
//            self.lookAroundScene = nil
//        }
//    }
//
//    private func calculateDrivingRoute() {
//        guard let userLocation = locationManager.currentLocation?.coordinate,
//              let destination = destination else { return }
//
//        let request = MKDirections.Request()
//        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation))
//        request.destination = destination
//        request.transportType = .automobile
//
//        Task {
//            let directions = MKDirections(request: request)
//            do {
//                let response = try await directions.calculate()
//                if let route = response.routes.first {
//                    self.route = route
//                    self.cameraPosition = .rect(route.polyline.boundingMapRect.insetBy(dx: -1000, dy: -1000))
//                }
//            } catch {
//                print("Route calculation Error: \(error.localizedDescription)")
//            }
//        }
//    }
//
//    private func resetAll() {
//        destination = nil
//        selectedItem = nil
//        route = nil
//        showLookAround = false
//        lookAroundScene = nil
//        updateCameraToUserLocation()
//    }
//
//    private func updateCameraToUserLocation() {
//        if let userLocation = locationManager.currentLocation?.coordinate {
//            cameraPosition = .region(MKCoordinateRegion(
//                center: userLocation,
//                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
//            ))
//        }
//    }
//
//    private func calculateMapRect(for coordinates: [CLLocationCoordinate2D]) -> MKMapRect {
//        var mapRect = MKMapRect.null
//        for coordinate in coordinates {
//            let point = MKMapPoint(coordinate)
//            let pointRect = MKMapRect(x: point.x, y: point.y, width: 0, height: 0)
//            mapRect = mapRect.union(pointRect)
//        }
//        return mapRect.insetBy(dx: -2000, dy: -2000)
//    }
//}




import SwiftUI
import MapKit
import CoreLocation

struct MapView: View {
    @State private var locationManager = LocationManager()
    @State private var searchText = ""
    @State private var destination: MKMapItem?
    @State private var selectedItem: MKMapItem?
    @State private var route: MKRoute?
    @State private var showLookAround = false
    @State private var lookAroundScene: MKLookAroundScene?
    @State private var isSearching = false

    @State private var cameraPosition: MapCameraPosition = .automatic
    
    // HKU 主要建筑坐标
    private let hkuBuildings: [HKUBuilding] = [
        HKUBuilding(name: "Main Building", coordinate: CLLocationCoordinate2D(latitude: 22.2828, longitude: 114.13771), description: "University's central administrative building"),
        HKUBuilding(name: "Library", coordinate: CLLocationCoordinate2D(latitude: 22.2835, longitude: 114.1370), description: "Main University Library"),
        HKUBuilding(name: "Engineering Building", coordinate: CLLocationCoordinate2D(latitude: 22.2825, longitude: 114.1365), description: "Faculty of Engineering"),
        HKUBuilding(name: "Science Building", coordinate: CLLocationCoordinate2D(latitude: 22.2820, longitude: 114.1380), description: "Faculty of Science"),
        HKUBuilding(name: "Medical Building", coordinate: CLLocationCoordinate2D(latitude: 22.2840, longitude: 114.1360), description: "Li Ka Shing Faculty of Medicine"),
        HKUBuilding(name: "Business School", coordinate: CLLocationCoordinate2D(latitude: 22.2815, longitude: 114.1375), description: "HKU Business School"),
        HKUBuilding(name: "Student Union", coordinate: CLLocationCoordinate2D(latitude: 22.2838, longitude: 114.1382), description: "HKU Student Union Building"),
        HKUBuilding(name: "Sports Centre", coordinate: CLLocationCoordinate2D(latitude: 22.2845, longitude: 114.1390), description: "Stanley Ho Sports Centre"),
        HKUBuilding(name: "Centennial Campus", coordinate: CLLocationCoordinate2D(latitude: 22.2850, longitude: 114.1350), description: "Centennial Campus"),
        HKUBuilding(name: "Kadoorie Building", coordinate: CLLocationCoordinate2D(latitude: 22.2828, longitude: 114.1368), description: "Kadoorie Biological Sciences Building")
    ]
    
    // HKU 校园中心坐标
    private let hkuCampusCenter = CLLocationCoordinate2D(latitude: 22.283, longitude: 114.137)

    var body: some View {
        VStack {
            HStack {
                TextField("Search building or location...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        geocodeDestination()
                    }
                
                if !searchText.isEmpty {
                    Button("Cancel") {
                        searchText = ""
                        resetAll()
                    }
                }
            }
            .padding(.horizontal)

            Map(position: $cameraPosition, selection: $selectedItem) {
                // 用户位置
                if let userLocation = locationManager.currentLocation?.coordinate {
                    Annotation("My location", coordinate: userLocation) {
                        ZStack {
                            Circle()
                                .fill(.blue.opacity(0.8))
                                .frame(width: 20, height: 20)
                            Circle()
                                .stroke(.white, lineWidth: 2)
                                .frame(width: 24, height: 24)
                        }
                    }
                }
                
                // HKU 建筑标注
                ForEach(hkuBuildings) { building in
                    Annotation(building.name, coordinate: building.coordinate) {
                        VStack(spacing: 4) {
                            Image(systemName: getBuildingIcon(for: building.name))
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(
                                    Circle()
                                        .fill(getBuildingColor(for: building.name))
                                )
                            
                            Text(building.name)
                                .font(.system(size: 10, weight: .medium))
                                .padding(4)
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(4)
                                .shadow(radius: 2)
                        }
                    }
                }

                // 搜索目的地
                if let destination = destination {
                    Marker(
                        destination.name ?? "Destination",
                        systemImage: "mappin.circle.fill",
                        coordinate: destination.placemark.coordinate
                    )
                    .tint(.red)
                }

                // 路线
                if let route = route {
                    MapPolyline(route.polyline)
                        .stroke(.blue, lineWidth: 6)
                }
            }
            .mapStyle(.standard(elevation: .realistic))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
                MapPitchToggle()
            }
            .onChange(of: selectedItem) { oldValue, newValue in
                handleSelection(newValue)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                // Look Around 预览
                if showLookAround, let scene = lookAroundScene {
                    LookAroundPreview(initialScene: scene)
                        .frame(height: 200)
                        .cornerRadius(12)
                        .padding()
                }
                
                if destination != nil {
                    Button("Show Driving Route") {
                        calculateDrivingRoute()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
            }
        }
        .onAppear {
            locationManager.startUpdatingLocation()
            // 设置初始视角为 HKU 校园
            setHKUCampusView()
        }
        .onChange(of: locationManager.currentLocation) { oldValue, newValue in
            if destination == nil {
                // 保持校园视图，不自动跳转到用户位置
                // setHKUCampusView()
            }
        }
    }
    
    private func setHKUCampusView() {
        cameraPosition = .region(MKCoordinateRegion(
            center: hkuCampusCenter,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005) // 更小的范围，更放大的视图
        ))
    }
    
    private func getBuildingIcon(for buildingName: String) -> String {
        switch buildingName {
        case "Library":
            return "books.vertical.fill"
        case "Sports Centre":
            return "sportscourt.fill"
        case "Student Union":
            return "person.3.fill"
        case "Medical Building":
            return "stethoscope"
        case "Science Building", "Engineering Building":
            return "atom"
        case "Business School":
            return "briefcase.fill"
        default:
            return "building.fill"
        }
    }
    
    private func getBuildingColor(for buildingName: String) -> Color {
        switch buildingName {
        case "Library":
            return .blue
        case "Sports Centre":
            return .green
        case "Student Union":
            return .orange
        case "Medical Building":
            return .red
        case "Science Building":
            return .purple
        case "Engineering Building":
            return .indigo
        case "Business School":
            return .teal
        default:
            return .gray
        }
    }

    private func geocodeDestination() {
        guard !searchText.isEmpty else { return }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = MKCoordinateRegion(
            center: hkuCampusCenter,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )

        let search = MKLocalSearch(request: request)
        search.start { response, error in
            if let error = error {
                print("Search Error: \(error.localizedDescription)")
                return
            }
            
            guard let mapItem = response?.mapItems.first else {
                print("Result not found")
                return
            }
            
            self.destination = mapItem
            self.selectedItem = mapItem
            
            // 移动到搜索结果位置，但保持适当的缩放级别
            self.cameraPosition = .region(MKCoordinateRegion(
                center: mapItem.placemark.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            ))
        }
    }

    private func handleSelection(_ item: MKMapItem?) {
        if let item = item {
            Task {
                let request = MKLookAroundSceneRequest(mapItem: item)
                if let scene = try? await request.scene {
                    self.lookAroundScene = scene
                    self.showLookAround = true
                } else {
                    self.lookAroundScene = nil
                    self.showLookAround = true
                }
            }
        } else {
            self.showLookAround = false
            self.lookAroundScene = nil
        }
    }

    private func calculateDrivingRoute() {
        guard let userLocation = locationManager.currentLocation?.coordinate,
              let destination = destination else { return }

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation))
        request.destination = destination
        request.transportType = .automobile

        Task {
            let directions = MKDirections(request: request)
            do {
                let response = try await directions.calculate()
                if let route = response.routes.first {
                    self.route = route
                    self.cameraPosition = .rect(route.polyline.boundingMapRect.insetBy(dx: -500, dy: -500))
                }
            } catch {
                print("Route calculation Error: \(error.localizedDescription)")
            }
        }
    }

    private func resetAll() {
        destination = nil
        selectedItem = nil
        route = nil
        showLookAround = false
        lookAroundScene = nil
        setHKUCampusView() // 重置时回到校园视图
    }

    private func updateCameraToUserLocation() {
        if let userLocation = locationManager.currentLocation?.coordinate {
            cameraPosition = .region(MKCoordinateRegion(
                center: userLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            ))
        }
    }
}

// HKU 建筑数据模型
struct HKUBuilding: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let description: String
}
