//
//  OrderedApp.swift
//  Ordered
//
//  Created by Kai Hin Hung on 9/7/2024.
//

import SwiftUI
import UIKit
import CoreLocation

@main
struct OrderedApp: App {
    let persistenceController = PersistenceController.shared
    
    @AppStorage("welcomeScreen") var welcomeScreen: Bool = true
    
    init(){
        
    }
    
    var body: some Scene {
        WindowGroup {
            //Tutorial
//            if welcomeScreen {
//
//            }
//            else{
            
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .task{
                        //Load Data
                    }
                    .onAppear {
                        LocationManager.shared.requestPermissions()
                    }
//            }
            
        }
    }
}

// Source: https://www.youtube.com/watch?v=6SWrpjTMvzs&ab_channel=codingKo
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            if let window = (application.connectedScenes.first as? UIWindowScene)?.windows.first {
                window.backgroundColor = UIColor(Color(.pageBackground))
            }
        }
        return true
    }
}


class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()

    private let locationManager = CLLocationManager()

    override private init() {
        super.init()
        locationManager.delegate = self
    }

    func requestPermissions() {
        if locationManager.authorizationStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if locationManager.authorizationStatus == .authorizedWhenInUse {
            locationManager.requestAlwaysAuthorization()
        }
    }

    func setupGeofence() {
        let coordinate = CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090) // Apple HQ
        let region = CLCircularRegion(center: coordinate, radius: 100, identifier: "AppleHQ")
        region.notifyOnEntry = true
        region.notifyOnExit = true

        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            locationManager.startMonitoring(for: region)
            print("Started monitoring region: \(region.identifier)")
        }
    }

    // MARK: - Delegate Methods

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways:
            print("Authorized Always")
            setupGeofence()
        case .authorizedWhenInUse:
            print("Authorized When In Use - Requesting Always")
            locationManager.requestAlwaysAuthorization()
        case .denied, .restricted:
            print("Location permission denied or restricted")
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("Entered region: \(region.identifier)")
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Exited region: \(region.identifier)")
    }
}
