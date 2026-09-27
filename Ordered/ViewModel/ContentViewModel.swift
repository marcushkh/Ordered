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
    
    @AppStorage("DefaultPage") private var defaultPage: TabBarItem = TabBarItem.quick
    @AppStorage("DidSetQuickDefaultPage") private var didSetQuickDefaultPage = false
    @Published var currentTab: TabBarItem = TabBarItem.quick
    @Published var showQuickFinishSearch = false
    @Published var showQuickFinishEditor = false
    @Published var quickFinishSearchText = ""
    @Published var isShowLibrary = false
    
    @Published var showEventDetail = false
    @Published var eventDetail: Event_Cal? = nil
    @Published var editEvent_Cal: Event_Cal? = nil
    
    //Create Event_Cal
    @Published var showCreateEvent = false
    @Published var createEvent_Section_Cal: Section_Cal? = nil
    @Published var createEvent_Section: Section? = nil
    
    //Change Event
    @Published var showChangeEvent = false
    @Published var changeEvent: Event? = nil
    
    //Change Section
    @Published var showSelectSection = false
    @Published var changeSection_Cal: Section_Cal? = nil
    @Published var changeSection: Section? = nil
    @Published var insertToCal: Cal? = nil
    @Published var insertIndex: Int? = nil
    
    //For Planning page
    @Published var highlightedEC: Event_Cal? = nil
    @Published var highlightedSC: Section_Cal? = nil
    
    //For Empty Event Selection
    @Published var showEmptyEventSelection = false
    @Published var emptyEventCal: Event_Cal? = nil
    @Published var eventSelectionSectionCal: Section_Cal? = nil
    
    //for welcome and showcase
    @Published var showCase = false
    @Published var isShowPaywall = false
    
    @Published var isSubscriptionActive = false
    
    init(){
        // Adopt Quick for existing installs once, then respect future settings changes.
        if !didSetQuickDefaultPage {
            defaultPage = .quick
            didSetQuickDefaultPage = true
        }
        currentTab = defaultPage
        
        Purchases.shared.getCustomerInfo { customerInfo, error in
            self.isSubscriptionActive = customerInfo?.entitlements.all["Premium"]?.isActive == true
        }
    }
}
