//
//  ContentViewModel.swift
//  Ordered
//
//  Created by Kai Hin Hung on 31/7/2024.
//

import SwiftUI
import RevenueCat

class ContentViewModel: ObservableObject{
    
    @Published var refresh = false
    // 0 is compact, 1 is fully expanded; intermediate values follow the user's drag.
    @Published var planBarExpansion: CGFloat = 1

    func resizePlanBar(by distance: CGFloat) {
        planBarExpansion = min(1, max(0, planBarExpansion + distance / 78))
    }
    func plan(_ event: Event) throws {
        try event.addToPlan()
    }

    func clearPlan() throws {
        try Event.clearPlan(in: Model.viewContext)
    }

    func removeFromPlan(_ event: Event) throws {
        try event.removeFromPlan()
    }

    @AppStorage("DefaultPage") private var defaultPage: TabBarItem = TabBarItem.quick
    @AppStorage("DidSetQuickFinishDefaultPage") private var didSetQuickFinishDefaultPage = false
    @Published var currentTab: TabBarItem = TabBarItem.quick
    @Published var showQuickFinishSearch = false
    @Published var showQuickFinishEditor = false
    @Published var quickFinishSearchText = ""
    @Published var libraryEditorRoute: LibraryEditorRoute?
    @Published var showChangeEvent = false
    @Published var changeEvent: Event? = nil

    // Onboarding and subscription
    @Published var isShowPaywall = false
    
    @Published var isSubscriptionActive = false
    
    init(){
        // Move retired opening-page choices to View, preserving all other choices.
        let savedPage = UserDefaults.standard.string(forKey: "DefaultPage")
        if savedPage == "home" || savedPage == "plan" {
            defaultPage = .view
            didSetQuickFinishDefaultPage = true
        } else if !didSetQuickFinishDefaultPage {
            defaultPage = .quick
            didSetQuickFinishDefaultPage = true
        }
        currentTab = defaultPage
        
        Purchases.shared.getCustomerInfo { customerInfo, error in
            self.isSubscriptionActive = customerInfo?.entitlements.all["Premium"]?.isActive == true
        }
    }
}
