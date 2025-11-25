import SwiftUI
import MapKit

struct CampusMapView: View {
    @StateObject private var locationManager = LocationManager.shared
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedBuilding: HKUBuilding?
    @State private var searchText = ""
    
    private let hkuBuildings = HKUBuilding.allBuildings
    private let hkuCampusCenter = CLLocationCoordinate2D(latitude: 22.283, longitude: 114.137)
    
    var body: some View {
        ZStack(alignment: .top) {

            baseMapView
            
            searchBar
            
            if let building = selectedBuilding {
                buildingDetailCard(building)
            }
        }
        .onAppear {
            locationManager.startUpdatingLocation()
            setCampusView()
        }
    }

    private var baseMapView: some View {
        Map(position: $cameraPosition) {
            // 用户位置
            if let userLocation = locationManager.currentLocation {
                Annotation("My Location", coordinate: userLocation.coordinate) {
                    UserLocationMarker()
                }
            }
            
            // 校园建筑
            ForEach(hkuBuildings) { building in
                Annotation("", coordinate: building.coordinate) {
                    BuildingAnnotationView(
                        building: building,
                        isSelected: selectedBuilding?.id == building.id
                    )
                    .onTapGesture {
                        withAnimation {
                            selectedBuilding = building
                            centerOnBuilding(building)
                        }
                    }
                }
            }
        }
        .mapStyle(.standard)
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .ignoresSafeArea()
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    private var searchBar: some View {
        VStack {
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search buildings...", text: $searchText)
                        .onSubmit {
                            hideKeyboard()
                        }
                        .submitLabel(.search)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(10)
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .shadow(radius: 3)
            }
            .padding(.horizontal)
            .padding(.top, 15)
            
            if !searchText.isEmpty {
                searchResultsList
            }
            
            Spacer()
        }
    }
    
    private var searchResultsList: some View {
        let filtered = hkuBuildings.filter { building in
            building.name.localizedCaseInsensitiveContains(searchText) ||
            building.description.localizedCaseInsensitiveContains(searchText)
        }
        
        return ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(filtered) { building in
                    Button(action: {
                        selectedBuilding = building
                        centerOnBuilding(building)
                        searchText = ""
                        hideKeyboard()
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(building.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            Text(building.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Divider()
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(radius: 3)
        }
        .frame(maxHeight: 300)
        .padding(.horizontal)
        .onTapGesture {
                
        }
    }
    
    private func buildingDetailCard(_ building: HKUBuilding) -> some View {
        VStack {
            Spacer()
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(building.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(building.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            selectedBuilding = nil
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.red)
                    
                    Text("Lat: \(building.coordinate.latitude, specifier: "%.4f")")
                        .font(.caption)
                    
                    Text("Lon: \(building.coordinate.longitude, specifier: "%.4f")")
                        .font(.caption)
                    
                    Spacer()
                }
                
                Button(action: {
                    navigateToBuilding(building)
                }) {
                    HStack {
                        Image(systemName: "location.fill")
                        Text("Get Directions")
                        Spacer()
                        Image(systemName: "arrow.up.forward")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 10)
            .padding(.horizontal)
            .padding(.bottom, 70)
            .transition(.move(edge: .bottom))
        }
    }
    
    private func setCampusView() {
        cameraPosition = .region(MKCoordinateRegion(
            center: hkuCampusCenter,
            span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        ))
    }
    
    private func centerOnBuilding(_ building: HKUBuilding) {
        withAnimation {
            cameraPosition = .region(MKCoordinateRegion(
                center: building.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)
            ))
        }
    }
    
    private func navigateToBuilding(_ building: HKUBuilding) {
        let placemark = MKPlacemark(coordinate: building.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = building.name
        
        let options = [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
        ]
        
        mapItem.openInMaps(launchOptions: options)
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct UserLocationMarker: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(.blue)
                .frame(width: 20, height: 20)
            Circle()
                .stroke(.white, lineWidth: 2)
                .frame(width: 24, height: 24)
        }
    }
}

struct BuildingAnnotationView: View {
    let building: HKUBuilding
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: building.iconName)
                .font(.system(size: isSelected ? 20 : 16))
                .foregroundColor(.white)
                .padding(8)
                .background(
                    Circle()
                        .fill(building.color)
                )
            
            Text(building.name)
                .font(.system(size: 10, weight: .medium))
                .padding(4)
                .background(Color.white)
                .cornerRadius(4)
        }
    }
}

struct CampusMapView_Previews: PreviewProvider {
    static var previews: some View {
        CampusMapView()
    }
}
