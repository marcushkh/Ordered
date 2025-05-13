//
//  MorningRoutineCase.swift
//  Ordered
//
//  Created by Kai Hin Hung on 29/8/2024.
//

import SwiftUI

struct Personal: View {
    
    @ObservedObject var welcomeVM: WelcomeVM
    
    var body: some View {
        
        VStack(alignment: .leading){
            Text("Design Your Dream Day")
                .font(.title2)
                .bold()
            Text("Be Productive After Work or School")
                .font(.title2)
                .bold()
                .padding(.bottom)
            
            EventPicker(sectionName: K.defaultSection[2], selectedEvents: $welcomeVM.personalEvents)
            
        }
        .padding(.top)
    }
}

#Preview {
    Personal(welcomeVM: WelcomeVM())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
