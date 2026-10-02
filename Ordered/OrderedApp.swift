//
//  OrderedApp.swift
//  Ordered
//
//  Created by Kai Hin Hung on 9/7/2024.
//

import AppIntents
import SwiftUI
import UIKit

@main
struct OrderedApp: App {
    @StateObject private var persistenceController = PersistenceController.shared
    
    @AppStorage("welcomeScreen") var welcomeScreen: Bool = true
    
    init() {
        OrderedShortcuts.updateAppShortcutParameters()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if persistenceController.isReady {
                    ContentView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                } else if let error = persistenceController.loadingError {
                    ContentUnavailableView {
                        Label("Couldn't Open Your Data", systemImage: "externaldrive.badge.exclamationmark")
                    } description: {
                        Text("Your saved data has been kept. \(error)")
                    } actions: {
                        Button("Try Again") { persistenceController.load() }
                    }
                } else {
                    ProgressView("Loading…")
                }
            }
            .preferredColorScheme(K.darkModeEnabled ? nil : .light)
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
