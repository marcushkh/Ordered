//
//  ContentView.swift
//  Ordered
//
//  Created by Kai Hin Hung on 9/7/2024.
//

import SwiftUI
import CoreData
import PopupView
import RevenueCat
import RevenueCatUI

struct ContentView: View {

    @Environment(\.managedObjectContext) private var viewContext
    @StateObject var viewModel = ContentViewModel()
    @StateObject var dayPlannerVM = DayPlannerViewModel()
    
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
                    TopBar(viewModel: viewModel, dayPlannerVM: dayPlannerVM)
                        .onTapGesture {
                            searchTyping = false
                        }
                    
                    //Main page
                    if [TabBarItem.home, TabBarItem.plan].contains(viewModel.currentTab){
                        //Records
                        MainList(viewModel: viewModel, dayPlannerVM: dayPlannerVM)
                            .ignoresSafeArea()
                            
                    }
                    else if viewModel.currentTab == .sugg{
                        
                    }
                    else if viewModel.currentTab == .statistic{
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            
                            TextField("Search Event", text: $viewModel.searchEventName)
                                .textFieldStyle(PlainTextFieldStyle())
                                .focused($searchTyping)
                        }
                        .padding(.vertical)
                        .padding(.horizontal, w * 0.075)
                        
                        EventList(viewModel: viewModel, eventName: $viewModel.searchEventName, selectedEvent: $viewModel.selectedEvent, toggleHeartSelectEvent: true)
                            .padding(.horizontal, w * 0.075)
                            .padding(.bottom, searchTyping ? 0 : 70)
                            .onAppear{
                                viewModel.selectedEvent = nil
                            }
                    }
                    else if viewModel.currentTab == .map{
                        CustomMapView(viewModel: viewModel)
//                        GeofencingView()
                    }
                    else if viewModel.currentTab == .setting{
                        SettingView()
                    }
                    
                    
                    // Bottom Bar
                    if viewModel.currentTab == .plan{
                        EventBar(viewModel: viewModel, dayPlannerVM: dayPlannerVM)
                            .onDisappear{
                                viewModel.highlightedEC = nil
                                viewModel.highlightedSC = nil
                            }
                            .onTapGesture {
                                
                            }
                    }
                }
                .frame(width: w, height: h)
                .overlay(alignment: .bottom){// TabBar
                    if !searchTyping{
                        BottomBar(viewModel: viewModel)
                            .padding(.bottom, 10)
                    }
                }
                
                .popup(isPresented: $viewModel.showEventDetail){
                    EventDetailPopup(viewModel: viewModel)
                } customize: {
                    $0
                        .type(.floater())
                        .closeOnTap(false)
                        .closeOnTapOutside(true)
                        .backgroundColor(.cPrimary.opacity(0.2))
                }
                .popup(isPresented: $viewModel.showLocationEventList){
                    LocationPopup(viewModel: viewModel, dayPlannerVM: dayPlannerVM)
                } customize: {
                    $0
                        .type(.floater())
                        .closeOnTap(false)
                        .closeOnTapOutside(true)
                        .dragToDismiss(false)
                        .backgroundColor(.cPrimary.opacity(0.2))
                }
                .popup(isPresented: $viewModel.showSelectLocation) {
                    //select Location
                    SelectLocation(viewModel: viewModel)
                } customize: {
                    $0
                        .type(.floater())
                        .closeOnTap(false)
                        .closeOnTapOutside(true)
                        .dragToDismiss(false)
                        .backgroundColor(.cPrimary.opacity(0.2))
                }
                .popup(isPresented: $viewModel.showEmptyEventSelection) {
                    //Empty Event Selection
                    EmptyEventSelectionPopup(viewModel: viewModel)
                } customize: {
                    $0
                        .type(.floater())
                        .closeOnTap(false)
                        .closeOnTapOutside(true)
                        .dragToDismiss(false)
                        .backgroundColor(.cPrimary.opacity(0.2))
                }
                .overlay{
                    if welcomeScreen {
                        WelcomeScreen(viewModel: viewModel)
                            .background()
                    }
                }
                .overlay{
                    if(viewModel.showChangeLocation){
                        ChangeLocation(viewModel: viewModel)
                    }
                }
                
                .sheet(isPresented: $viewModel.showChangeEvent){
                    ChangeEvent(viewModel: viewModel)
                }
                .sheet(isPresented: $viewModel.showCreateEvent, onDismiss: {
                    viewModel.createEvent_Section_Cal = nil
                    viewModel.createEvent_Section = nil
                    viewModel.refresh.toggle()
                }) {
                    CreateEvent(viewModel: viewModel, editEvent_Cal: viewModel.editEvent_Cal, date: dayPlannerVM.currentDate, display: $viewModel.showCreateEvent)
                        .presentationCornerRadius(K.presentationCornerRadius)
                }
                .onChange(of: viewModel.currentTab) { oldValue, newValue in
                    if viewModel.currentTab != .plan{
                        withAnimation {
                            viewModel.highlightedEC = nil
                            viewModel.highlightedSC = nil
                        }
                    }
                    
                }
                //On change of Cal
                .onChange(of: viewModel.refresh) { oldValue, newValue in
                    LiveActivityActions.refreshLiveActivities()
                }
                // when the app is re-entered set to current date
                .onChange(of: scenePhase, { oldValue, newValue in
                    if newValue == .active {
                        dayPlannerVM.setCurrentDate(to: MyCalendar.getToday())
                    }
                })
            }
            .onTapGesture {
                withAnimation {
                    if viewModel.currentTab == .plan{
                        if viewModel.currentTab == .plan{
                            viewModel.currentTab = .home
                        }
                        viewModel.highlightedEC = nil
                        viewModel.highlightedEC = nil
                    }
                }
            }
            .modifier(ShowCaseRoot(showHighlights: viewModel.showCase, onFinished: {
                if !viewModel.isSubscriptionActive{
                    viewModel.isShowPaywall = true
                }
            }))
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
            .onAppear {
                if !welcomeScreen{
                    MovementDetection.shared.startMonitoring()
                }
            }
        }
        
    }
}

