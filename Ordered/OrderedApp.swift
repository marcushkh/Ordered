//
//  OrderedApp.swift
//  Ordered
//
//  Created by Kai Hin Hung on 9/7/2024.
//

import SwiftUI

@main
struct OrderedApp: App {
    let persistenceController = PersistenceController.shared
    @AppStorage("preload") var preload: Bool = false
    
    //To be deleted:
    private var viewContext = PersistenceController.shared.container.viewContext
    
    
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
