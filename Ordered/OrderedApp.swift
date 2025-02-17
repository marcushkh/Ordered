//
//  OrderedApp.swift
//  Ordered
//
//  Created by Kai Hin Hung on 9/7/2024.
//

import SwiftUI
import UIKit

@main
struct OrderedApp: App {
    let persistenceController = PersistenceController.shared
    
    @AppStorage("welcomeScreen") var welcomeScreen: Bool = false
    @AppStorage("initData") var initData: Bool = false
    
    init(){
        
    }
    
    var body: some Scene {
        WindowGroup {
            
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .task{
                    //Load Data
                }
            
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
