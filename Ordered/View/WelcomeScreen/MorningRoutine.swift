//
//  MorningRoutineCase.swift
//  Ordered
//
//  Created by Kai Hin Hung on 29/8/2024.
//

import SwiftUI

struct MorningRoutine: View {
    
    @ObservedObject var welcomeVM: WelcomeVM
    
    var body: some View {
        
        VStack(alignment: .leading){
            Text("Design Your Dream Day")
                .font(.title2)
                .bold()
            Text("A Good Day Starts Every Morning")
                .font(.title2)
                .bold()
                .padding(.bottom)
            
            EventPicker(sectionName: "Morning Routine", selectedEvents: $welcomeVM.morningEvents)
            
        }
        .padding(.top)
    }
}

#Preview {
    MorningRoutine(welcomeVM: WelcomeVM())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
