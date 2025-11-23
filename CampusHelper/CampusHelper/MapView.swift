import SwiftUI
import MapKit

struct MapView: View {
    // 深圳中心坐标
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 22.5429, longitude: 114.0596),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )
    
    @State private var searchText = ""
    @State private var annotations = [CampusAnnotation]()
    // 添加底部导航选中状态绑定
    @Binding var selectedTab: Int
    
    var body: some View {
        VStack {
            // 搜索栏
            TextField("Search location (e.g., Shenzhen Civic Center, Window of the World)", text: $searchText)
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding()
            
            // 地图视图
            Map(coordinateRegion: $region, annotationItems: annotations) { annotation in
                MapPin(coordinate: annotation.coordinate, tint: .red)
            }
            .ignoresSafeArea(edges: .bottom)
            .padding(.bottom, 34) // 预留底部导航栏空间
        }
        .navigationTitle("Shenzhen Map")
        .onAppear {
            // 初始化地标数据
            annotations = [
                CampusAnnotation(name: "Shenzhen Civic Center", coordinate: CLLocationCoordinate2D(latitude: 22.5430, longitude: 114.0570)),
                CampusAnnotation(name: "Window of the World", coordinate: CLLocationCoordinate2D(latitude: 22.5331, longitude: 113.9612)),
                CampusAnnotation(name: "Lianhuashan Park", coordinate: CLLocationCoordinate2D(latitude: 22.5547, longitude: 114.0488)),
                CampusAnnotation(name: "Shenzhen North Railway Station", coordinate: CLLocationCoordinate2D(latitude: 22.6165, longitude: 114.0225)),
                CampusAnnotation(name: "Dameisha Beach", coordinate: CLLocationCoordinate2D(latitude: 22.6560, longitude: 114.2870))
            ]
        }
    }
}

// 同时需要更新ContentView中的TabView配置，启用地图页：
/* 在ContentView.swift中找到被注释的地图页代码，修改为：
// 3. 地图页
MapView(selectedTab: $selectedTab)
    .tabItem {
        Image(systemName: "map.fill")
        Text("Map")
    }
    .tag(2)
*/

struct MapView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MapView(selectedTab: .constant(2))
        }
    }
}
