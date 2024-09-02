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
    
    //To be deleted:
    private var viewContext = PersistenceController.shared.container.viewContext
    
    init(){
        if !initData{ //Need to add the logic of if the data is not empty, initData = true
            let morningRoutine = Models.saveSection(name: "Morning Routine", color: "F5D657")
            let schedule = Models.saveSection(name: "Schedule", color: "57B2BF")
            
            for i in K.morningRoutineSample{
                let event = Models.saveEvent(icon: i[0] as! String, name: i[1] as! String, duration: i[2] as! Int)
                
                Models.add(event: event, to: morningRoutine)
            }
            
            for i in K.scheduleSample{
                let event = Models.saveEvent(icon: i[0] as! String, name: i[1] as! String, duration: i[2] as! Int)
                Models.add(event: event, to: schedule)
            }
            
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
