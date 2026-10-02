//
//  ContentView.swift
//  Ordered
//
//  Created by Kai Hin Hung on 9/7/2024.
//

import SwiftUI
import CoreData
import RevenueCat
import RevenueCatUI

struct ContentView: View {

    @Environment(\.managedObjectContext) private var viewContext
    @StateObject var viewModel = ContentViewModel()
    @StateObject var dayPlannerVM = DayPlannerViewModel()
    @StateObject var statViewModel = StatViewModel()
    
    @AppStorage("welcomeScreen") var welcomeScreen: Bool = true
    
    @FocusState var searchTyping: Bool
    @Environment(\.scenePhase) private var scenePhase
    
    init(){
        #if DEBUG
//        welcomeScreen = true
        #endif
        Purchases.configure(withAPIKey: "appl_xnYsiELHTsABRcVdfAShQCpYvQK")
    }
    
    var body: some View {
        GeometryReader{ geo in
            let w = geo.size.width
            let h = geo.size.height
            
            Background(color: .cBackground, allFocusStates: [$searchTyping]){
                VStack(spacing: 0){
                    //Top Bar
                    TopBar(
                        viewModel: viewModel,
                        dayPlannerVM: dayPlannerVM,
                        statViewModel: statViewModel
                    )
                        .onTapGesture {
                            searchTyping = false
                        }
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(2)
                    
                    //Main page
                    if viewModel.currentTab == .view {
                        CompletedEventsView(viewModel: viewModel)
                    }
                    else if viewModel.currentTab == .library {
                        LibraryEditorView(viewModel: viewModel)
                    }
                    else if viewModel.currentTab == .quick {
                        QuickFinishView(
                            viewModel: viewModel,
                            dayPlannerVM: dayPlannerVM
                        )
                    }
                    else if viewModel.currentTab == .statistic{
                        Stat(viewModel: statViewModel, dayPlannerVM: dayPlannerVM)
                    }
                    else if viewModel.currentTab == .setting{
                        SettingView(viewModel: viewModel)
                    }
                    
                    
                }
                .frame(width: w, height: h)
                .overlay(alignment: .bottom){// TabBar
                    if !searchTyping{
                        TabBar(viewModel: viewModel)
                            .padding(.bottom, 10)
                    }
                }
                
                .overlay{
                    if welcomeScreen {
                        WelcomeScreen(viewModel: viewModel)
                            .background()
                    }
                }
                .sheet(isPresented: $viewModel.showChangeEvent){
                    ChangeEvent(viewModel: viewModel)
                }
                // when the app is re-entered set to current date
                .onChange(of: scenePhase, { oldValue, newValue in
                    if newValue == .active {
                        dayPlannerVM.setCurrentDate(to: MyCalendar.getToday())
                    }
                })
            }
            .sheet(isPresented: $viewModel.isShowPaywall) {
                PaywallView()
                    .onPurchaseCompleted { customerInfo in
                        viewModel.isSubscriptionActive = customerInfo.entitlements.all["Premium"]?.isActive == true
                        viewModel.isShowPaywall = false
                    }
                    .onRestoreCompleted { customerInfo in
                        viewModel.isSubscriptionActive = customerInfo.entitlements.all["Premium"]?.isActive == true
                        viewModel.isShowPaywall = false
                    }
            }
        }
        
    }
}
