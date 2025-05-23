import SwiftUI
import MapKit
import CoreLocation

struct MonitoredRegion: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let radius: CLLocationDistance
    var isInside: Bool = false
}

class GeofencingViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var monitoredRegions: [MonitoredRegion] = []
    @Published var userLocation: CLLocation?
    @Published var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    private let locationManager = CLLocationManager()
    private var initialLocationSet = false
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
        
        // Only set this if the app has background capability
        if Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") != nil {
            let backgroundModes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String]
            if backgroundModes?.contains("location") == true {
                locationManager.allowsBackgroundLocationUpdates = true
                print("Background location updates enabled")
            } else {
                print("App does not have background location capability")
            }
        }
        
        checkLocationAuthorization()
    }
    
    func checkLocationAuthorization() {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            // Handle alert to tell users how to turn on permissions
            break
        @unknown default:
            break
        }
    }
    
    func addCurrentLocationFence() {
        guard let location = userLocation else { 
            print("Cannot add geofence: No user location available")
            return 
        }
        
        // Create a new region
        let region = MonitoredRegion(
            coordinate: location.coordinate,
            radius: 100 // 100 meters radius
        )
        
        // Add to our view model list
        monitoredRegions.append(region)
        
        // Set up actual geofence monitoring
        let circularRegion = CLCircularRegion(
            center: location.coordinate,
            radius: region.radius,
            identifier: region.id.uuidString
        )
        circularRegion.notifyOnEntry = true
        circularRegion.notifyOnExit = true
        
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            locationManager.startMonitoring(for: circularRegion)
            print("Started monitoring region: \(circularRegion.identifier)")
        } else {
            print("Region monitoring not available for this device")
        }
        
        // Update map region to show the new fence
        mapRegion = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    }
    
    func centerMapOnUser() {
        guard let location = userLocation else { return }
        
        DispatchQueue.main.async {
            self.mapRegion = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            )
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        DispatchQueue.main.async {
            self.userLocation = location
            
            // First time we get a location, center the map on the user
            if !self.initialLocationSet {
                self.initialLocationSet = true
                self.mapRegion = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
                print("Map centered on user's initial location")
            }
            
            // Check if we're in any of our regions
            for i in 0..<self.monitoredRegions.count {
                let distance = location.distance(from: CLLocation(
                    latitude: self.monitoredRegions[i].coordinate.latitude,
                    longitude: self.monitoredRegions[i].coordinate.longitude
                ))
                
                let wasInside = self.monitoredRegions[i].isInside
                let isInside = distance <= self.monitoredRegions[i].radius
                
                if wasInside != isInside {
                    // Status changed, update the region
                    self.monitoredRegions[i].isInside = isInside
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Entered region: \(region.identifier)")
        
        DispatchQueue.main.async {
            if let index = self.monitoredRegions.firstIndex(where: { $0.id.uuidString == region.identifier }) {
                self.monitoredRegions[index].isInside = true
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Exited region: \(region.identifier)")
        
        DispatchQueue.main.async {
            if let index = self.monitoredRegions.firstIndex(where: { $0.id.uuidString == region.identifier }) {
                self.monitoredRegions[index].isInside = false
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkLocationAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
}

// A simple SwiftUI Map implementation that should work better
struct SimpleGeofencingMapView: View {
    @Binding var region: MKCoordinateRegion
    let regions: [MonitoredRegion]
    
    var body: some View {
        // Using basic Map without content closure
        Map(coordinateRegion: $region, showsUserLocation: true)
    }
}

struct GeofencingView: View {
    @StateObject private var geoViewModel = GeofencingViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                // Basic map view with user location
                Map(coordinateRegion: $geoViewModel.mapRegion, showsUserLocation: true)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Show the regions as a list under the map
                if !geoViewModel.monitoredRegions.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Monitored Regions:")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(geoViewModel.monitoredRegions) { region in
                                    VStack {
                                        Text("Region \(region.id.uuidString.prefix(6))")
                                            .font(.caption)
                                            .lineLimit(1)
                                        
                                        Circle()
                                            .fill(region.isInside ? Color.green.opacity(0.3) : Color.red.opacity(0.3))
                                            .frame(width: 40, height: 40)
                                            .overlay(
                                                Circle()
                                                    .stroke(region.isInside ? Color.green : Color.red, lineWidth: 2)
                                            )
                                    }
                                    .frame(width: 80)
                                    .padding(.vertical, 5)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .scrollIndicators(.hidden)
                    }
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(10)
                    .padding()
                }
                
                HStack(spacing: 20) {
                    Button(action: {
                        geoViewModel.addCurrentLocationFence()
                    }) {
                        Text("Add Geofence")
                            .font(.headline)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        print("Center Map on User")
                        geoViewModel.centerMapOnUser()
                    }) {
                        Image(systemName: "location.fill")
                            .font(.headline)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.bottom, 80)
            }
            .navigationTitle("Geofencing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    GeofencingView()
} 
