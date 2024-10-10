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
    @AppStorage("welcomeScreen") var welcomeScreen: Bool = false
    @AppStorage("initData") var initData: Bool = false
    
    init(){
        if !initData{ //Need to add the logic of if the data is not empty, initData = true
            let morningRoutine = Models.saveSection(name: K.defaultSection[0], color: "F5D657")
            let schedule = Models.saveSection(name: K.defaultSection[1], color: "57B2BF")
            let personal = Models.saveSection(name: K.defaultSection[2], color: "F59057")
            let nightRoutine = Models.saveSection(name: K.defaultSection[3], color: "8057F5")
            
            Models.add(event: K.morningRoutineDefault, to: morningRoutine)
            Models.add(event: K.scheduleDefault, to: schedule)
            Models.add(event: K.personalDefault, to: personal)
            Models.add(event: K.nightRoutineDefault, to: nightRoutine)
            
            initData = true
        }
    }
    
    
    var body: some Scene {
        WindowGroup {
            if !welcomeScreen{
                WelcomeScreen()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            }
            else{
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .task{
                        //Load Data
                    }
            }
        }
    }
    
}
