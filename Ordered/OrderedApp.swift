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
    
    @UIApplicationDelegateAdaptor (AppDelegate.self) var appDelegate
    
    @AppStorage("welcomeScreen") var welcomeScreen: Bool = false
    @AppStorage("initData") var initData: Bool = false
    
    init(){
        if !initData{ //Need to add the logic of if the data is not empty, initData = true
            let morningRoutine = Section.save(name: K.defaultSection[0], color: "F5D657")
            let schedule = Section.save(name: K.defaultSection[1], color: "57B2BF")
            let personal = Section.save(name: K.defaultSection[2], color: "F59057")
            let nightRoutine = Section.save(name: K.defaultSection[3], color: "8057F5")
            
            morningRoutine.add(event: K.morningRoutineDefault)
            morningRoutine.add(event: K.scheduleDefault)
            morningRoutine.add(event: K.personalDefault)
            morningRoutine.add(event: K.nightRoutineDefault)
            
            initData = true
        }
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
                window.backgroundColor = UIColor(Color(hex: "c9cad5"))
                
            }
        }
        return true
    }
}
