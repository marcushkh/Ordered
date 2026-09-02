//
//  WelcomeScreen1.swift
//  Ordered
//
//  Created by Kai Hin Hung on 28/8/2024.
//

import SwiftUI
import PopupView

struct WelcomeScreen: View {
    @ObservedObject var viewModel: ContentViewModel
    @StateObject var welcomeVM = WelcomeVM()
    
    @State var currentItem = 0
    
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
                        HapticFeedback.light()
                    }
                }
                else{
                    if Event.count() == 0 {
                        currentItem = 1
                        welcomeVM.alertMessage = "Minimum of one event is required"
                        welcomeVM.showAlert = true
                    }
                    else{
                        withAnimation {
                            welcomeScreen = false
                            viewModel.showCase = true
                            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
                            HapticFeedback.heavy()
                        }
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
        .alert(welcomeVM.alertMessage, isPresented: $welcomeVM.showAlert) {
            Button{
                welcomeVM.showAlert = false
            } label: {
                Text("ok")
            }
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
            Personal(viewModel: viewModel, welcomeVM: welcomeVM)
            
        case listOfSteps[2]:
            Privacy()
            
        default:
            Text("Default")
        }
    }
}
