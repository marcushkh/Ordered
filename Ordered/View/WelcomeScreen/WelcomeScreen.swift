//
//  WelcomeScreen1.swift
//  Ordered
//
//  Created by Kai Hin Hung on 28/8/2024.
//

import SwiftUI
import PopupView

struct WelcomeScreen: View {
    @State var currentItem = 0
    @StateObject var welcomeVM = WelcomeVM()
    let listOfSteps = K.defaultSection
    
    var body: some View {
        VStack{
            ProgressStepBar(listOfTitle: listOfSteps, currentItem: $currentItem)
            
            Spacer()
            
            SwipeableStack(listOfSteps, jumpTo: listOfSteps[currentItem]) { d, pos in
                
                CaseSeparation(currentPage: d, listOfSteps: listOfSteps, welcomeVM: welcomeVM)
                    .onChange(of: d){
                        if pos == .centerView{
                            withAnimation {
                                currentItem = listOfSteps.firstIndex(of: d) ?? 0
                            }
                        }
                    }
            }
            
            Text("Next")
        }
        .padding(.horizontal, K.horizontal_padding)
        .padding(.top)
        .popup(isPresented: $welcomeVM.showSelectTime){
            TimeSelection(isPresented: $welcomeVM.showSelectTime, event: $welcomeVM.selectedEvent, eventList: $welcomeVM.scheduleEvents)
        } customize: {
            $0
                .type(.floater())
                .closeOnTap(false)
                .closeOnTapOutside(true)
                .backgroundColor(.black.opacity(0.5))
                .dragToDismiss(false)
        }
    }
}

struct CaseSeparation: View{
    var currentPage: String
    var listOfSteps: [String]
    @ObservedObject var welcomeVM: WelcomeVM
    
    var body: some View{
        switch(currentPage){
        case listOfSteps[0]:
            MorningRoutine(welcomeVM: welcomeVM)
            
        case listOfSteps[1]:
            Schedule(welcomeVM: welcomeVM)
            
        case listOfSteps[2]:
            Personal(welcomeVM: welcomeVM)
            
        case listOfSteps[3]:
            NightRoutine(welcomeVM: welcomeVM)
            
        default:
            Text("Default")
        }
    }
}

#Preview {
    WelcomeScreen()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
