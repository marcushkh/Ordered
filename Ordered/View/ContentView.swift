//
//  ContentView.swift
//  Ordered
//
//  Created by Kai Hin Hung on 9/7/2024.
//

import SwiftUI
import CoreData
import PopupView

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject var viewModel = ContentViewModel()
    @StateObject var dayPlannerVM = DayPlannerViewModel()
    
    @FocusState var searchTyping: Bool
    @Environment(\.scenePhase) private var scenePhase
    
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
                    else if viewModel.currentTab == .weeklyDefault{
                        if viewModel.showWeekDetail{
                            WeekDefaultMainList(viewModel: viewModel)
                        }
                        else{
                            WeekDefaultView(viewModel: viewModel)
                        }
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
                        
                        EventList(eventName: $viewModel.searchEventName, selectedEvent: $viewModel.selectedEvent, isChangeSelectedEvent: true)
                            .padding(.horizontal, w * 0.075)
                            .padding(.bottom, searchTyping ? 0 : 70)
                    }
                    
                    
                    // Bottom Bar
                    if viewModel.currentTab == .plan || (viewModel.currentTab == .weeklyDefault && viewModel.showEventBar){
                        EventBar(viewModel: viewModel, dayPlannerVM: dayPlannerVM)
                            .onDisappear{
                                viewModel.highlightedEC = nil
                                viewModel.showEventBar = false
                                viewModel.selectedWeekAb = nil
                            }
                    }
                }
                .frame(width: w, height: h)
                .overlay(alignment: .bottom){// TabBar
                    if !searchTyping{
                        BottomBar(viewModel: viewModel)
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
                .overlay{
                    if viewModel.showChangeSection{
                        ChangeSectionName(viewModel: viewModel)
                    }
                }
                .sheet(isPresented: $viewModel.showCreateEvent) {
                    CreateEvent(viewModel: viewModel, editEvent_Cal: viewModel.editEvent_Cal, date: dayPlannerVM.currentDate, display: $viewModel.showCreateEvent)
                        .presentationCornerRadius(K.presentationCornerRadius)
                        .onDisappear {
                            viewModel.createEvent_Section_Cal = nil
                            viewModel.createEvent_Section = nil
                            viewModel.refresh.toggle()
                        }
                    
                }
                .onChange(of: viewModel.currentTab) { oldValue, newValue in
                    if viewModel.currentTab != .weeklyDefault || viewModel.currentTab != .plan{
                        withAnimation {
                            viewModel.highlightedEC = nil
                        }
                    }
                    if viewModel.currentTab != .weeklyDefault{
                        viewModel.showEventBar = false
                        viewModel.selectedWeekAb = nil
                        viewModel.showWeekDetail = false
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
                    if viewModel.currentTab == .plan || viewModel.currentTab == .weeklyDefault{
                        if viewModel.currentTab == .plan{
                            viewModel.currentTab = .home
                        }
                        viewModel.highlightedEC = nil
                        viewModel.showEventBar = false
                        viewModel.selectedWeekAb = nil
                        viewModel.showWeekDetail = false
                    }
                }
            }
        }
    }
}

