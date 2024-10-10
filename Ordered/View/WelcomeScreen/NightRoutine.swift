//
//  MorningRoutineCase.swift
//  Ordered
//
//  Created by Kai Hin Hung on 29/8/2024.
//

import SwiftUI

struct NightRoutine: View {
    
    @ObservedObject var welcomeVM: WelcomeVM
    
    var body: some View {
        
        VStack(alignment: .leading){
            Text("Design Your Dream Day")
                .font(.title2)
                .bold()
            Text("A Great Night Routine")
                .font(.title2)
                .bold()
                .padding(.bottom)
            
            EventPicker(sectionName: K.defaultSection[3], selectedEvents: $welcomeVM.nightEvents)
            
        }
        .padding(.top)
    }
}

#Preview {
    NightRoutine(welcomeVM: WelcomeVM())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
