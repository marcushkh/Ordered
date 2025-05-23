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
    @ObservedObject var viewModel: ContentViewModel
    
    @AppStorage("welcomeScreen") var welcomeScreen: Bool = true
    
    let listOfSteps = K.defaultSection
    
    var body: some View {
        
        VStack{
            ProgressStepBar(listOfTitle: listOfSteps, currentItem: $currentItem)
            
            Spacer()
            
            SwipeableStack(listOfSteps, jumpTo: listOfSteps[currentItem]) { d, pos in
                
                CaseSeparation(currentPage: d, listOfSteps: listOfSteps, welcomeVM: welcomeVM, viewModel: viewModel)
                    .onChange(of: d){
                        if pos == .centerView{
                            withAnimation {
                                currentItem = listOfSteps.firstIndex(of: d) ?? 0
                            }
                        }
                    }
            }
            
            Button{
                if currentItem < listOfSteps.count - 1{
                    withAnimation {
                        currentItem += 1
                    }
                    
                }
                else{
                    //init database
                    withAnimation {
                        welcomeScreen = false
                    }
                }
            } label: {
                Text(currentItem < listOfSteps.count - 1 ? "Next" : "Start!")
                    .font(.title2)
                    .foregroundStyle(Color(.white))
                    .bold()
                    .padding([.top, .bottom], 10)
                    .padding([.leading, .trailing], UIScreen.main.bounds.width * 0.35)
                    .background(Color(hex: "484B6A"))
                    .clipShape(.rect(cornerRadius: 20))
            }
        }
        .padding(.horizontal, K.horizontal_padding)
        .padding(.vertical)
        .popup(isPresented: $welcomeVM.showPopup) {
            EventsForLocation(viewModel: viewModel, welcomeVM: welcomeVM)
        } customize: {
            $0
                .type(.floater())
                .closeOnTap(false)
                .closeOnTapOutside(true)
                .dragToDismiss(false)
                .backgroundColor(.cPrimary.opacity(0.1))
        }
        
        
        .popup(isPresented: $welcomeVM.showSelectTime){
            TimeSelection(isPresented: $welcomeVM.showSelectTime, event: $welcomeVM.selectedEvent, eventList: $welcomeVM.scheduleEvents)
        } customize: {
            $0
                .type(.floater())
                .closeOnTap(false)
                .closeOnTapOutside(true)
                .backgroundColor(.black.opacity(0.3))
                .dragToDismiss(false)
        }
        
    }
    
}

struct CaseSeparation: View{
    var currentPage: String
    var listOfSteps: [String]
    @ObservedObject var welcomeVM: WelcomeVM
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View{
        switch(currentPage){
        case listOfSteps[0]:
            Intro()
            
        case listOfSteps[1]:
            Personal(welcomeVM: welcomeVM, viewModel: viewModel)
            
        case listOfSteps[2]:
            LocationSelection(welcomeVM: welcomeVM)
            
        case listOfSteps[3]:
            Privacy()
            
        default:
            Text("Default")
        }
    }
}
