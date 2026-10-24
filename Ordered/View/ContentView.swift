//
//  ContentView.swift
//  Ordered
//
//  Created by Kai Hin Hung on 9/7/2024.
//

import SwiftUI
import Combine
import CoreData
import RevenueCat
import RevenueCatUI

struct ContentView: View {

    @Environment(\.managedObjectContext) private var viewContext
    @StateObject var viewModel = ContentViewModel()
    @StateObject var dayPlannerVM = DayPlannerViewModel()
    @StateObject var statViewModel = StatViewModel()
    
    @AppStorage("welcomeScreen") var welcomeScreen: Bool = true
    
    @AppStorage("DayStartTime") private var dayStartTime = MyCalendar.defaultDayStartHour
    @AppStorage("FirstWeekday") private var firstWeekday = 0
    private let dayClock = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    @FocusState var searchTyping: Bool
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
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
                        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: viewModel.currentTab)
                        .zIndex(2)
                    
                    // Keep each tab's identity, scroll position and loaded data.
                    TabView(selection: $viewModel.currentTab) {
                        QuickFinishView(viewModel: viewModel, dayPlannerVM: dayPlannerVM)
                            .toolbar(.hidden, for: .tabBar)
                            .tag(TabBarItem.quick)
                        CompletedEventsView(viewModel: viewModel)
                            .toolbar(.hidden, for: .tabBar)
                            .tag(TabBarItem.view)
                        LibraryEditorView(viewModel: viewModel)
                            .toolbar(.hidden, for: .tabBar)
                            .tag(TabBarItem.library)
                        Stat(appViewModel: viewModel, viewModel: statViewModel, dayPlannerVM: dayPlannerVM)
                            .showCase(.statistics)
                            .toolbar(.hidden, for: .tabBar)
                            .tag(TabBarItem.statistic)
                        SettingView()
                            .toolbar(.hidden, for: .tabBar)
                            .tag(TabBarItem.setting)
                    }

                }
                .frame(width: w, height: h)
                .overlay(alignment: .bottom){// TabBar
                    if !searchTyping{
                        TabBar(viewModel: viewModel)
                            .padding(.bottom, 10)
                    }
                }
                
                .tutorialShowCase(viewModel)
                .overlay{
                    if welcomeScreen {
                        WelcomeScreen(viewModel: viewModel)
                            .background()
                    }
                }
                .sheet(isPresented: $viewModel.showChangeEvent){
                    ChangeEvent(viewModel: viewModel)
                }
                .onAppear {
                    refreshCurrentDay()
                    if !welcomeScreen { viewModel.startTutorialIfNeeded() }
                }
                .onChange(of: welcomeScreen) { _, isShowing in
                    if !isShowing { viewModel.startTutorialIfNeeded() }
                }
                .onChange(of: viewModel.tutorial.isActive) { wasActive, isActive in
                    if wasActive && !isActive {
                        viewModel.presentTutorialFollowUpIfNeeded()
                    }
                }
                .onReceive(dayClock) { _ in refreshCurrentDay() }
                .onChange(of: dayStartTime) { _, _ in
                    refreshCurrentDay()
                    viewModel.viewedDate = MyCalendar.getToday()
                    statViewModel.returnToCurrentPeriod()
                }
                // when the app is re-entered set to current date
                .onChange(of: scenePhase, { oldValue, newValue in
                    if newValue == .active {
                        refreshCurrentDay()
                        Task { await viewModel.refreshSubscriptionStatus() }
                    }
                })
            }
            .sheet(isPresented: $viewModel.isShowPaywall) {
                PaywallView()
                    .onPurchaseCompleted { customerInfo in
                        viewModel.updateSubscription(customerInfo)
                        if viewModel.isSubscriptionActive { viewModel.isShowPaywall = false }
                    }
                    .onRestoreCompleted { customerInfo in
                        viewModel.updateSubscription(customerInfo)
                        if viewModel.isSubscriptionActive { viewModel.isShowPaywall = false }
                    }
            }
        }
        .environment(\.calendar, preferredCalendar)
        .task { await viewModel.observeSubscriptionUpdates() }
        .task { await viewModel.refreshSubscriptionStatus() }
        .alert("Couldn't Check Subscription", isPresented: Binding(
            get: { viewModel.subscriptionError != nil },
            set: { if !$0 { viewModel.subscriptionError = nil } }
        )) {
            Button("OK", role: .cancel) { viewModel.subscriptionError = nil }
        } message: {
            Text(viewModel.subscriptionError ?? "Please try again.")
        }
    }
    private var preferredCalendar: Calendar {
        var calendar = Calendar.autoupdatingCurrent
        calendar.firstWeekday = MyCalendar.resolvedFirstWeekday(firstWeekday)
        return calendar
    }

    private func refreshCurrentDay() {
        let today = MyCalendar.getToday()
        if dayPlannerVM.currentDate != today {
            dayPlannerVM.setCurrentDate(to: today)
        }
    }

}
