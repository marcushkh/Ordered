//
//  WelcomeScreen1.swift
//  Ordered
//
//  Created by Kai Hin Hung on 28/8/2024.
//

import SwiftUI

struct WelcomeScreen: View {
    @State var currentItem = 0
    let listOfSteps = ["Morning Routine", "Occupation", "Personal Development", "Night Routine"]
    
    var body: some View {
        VStack{
            ProgressStepBar(listOfTitle: listOfSteps, currentItem: $currentItem)
            
            Spacer()
            
            SwipeableStack(listOfSteps, jumpTo: listOfSteps.first) { d, pos in
                
                caseSeparation(currentPage: d, listOfSteps: listOfSteps)
                    .onChange(of: d){
                        if pos == .centerView{
                            withAnimation {
                                currentItem = listOfSteps.firstIndex(of: d) ?? 0
                            }
                        }
                    }
            }
        }
        .padding(.horizontal, K.horizontal_padding)
        .padding(.top)
    }
}

struct caseSeparation: View{
    var currentPage: String
    var listOfSteps: [String]
    
    var body: some View{
        switch(currentPage){
        case listOfSteps[0]:
            MorningRoutine()
            
        case listOfSteps[1]:
            Text("JIJI")
            
        case listOfSteps[2]:
            Text("HIHI")
            
        case listOfSteps[3]:
            Text("JFDI")
            
        default:
            Text("Default")
        }
    }
}

#Preview {
    WelcomeScreen()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
