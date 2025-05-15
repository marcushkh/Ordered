//
//  ContentViewModel.swift
//  Ordered
//
//  Created by Kai Hin Hung on 31/7/2024.
//

import SwiftUI

class ContentViewModel: ObservableObject{
    
    @Published var refresh = false
    
    @AppStorage("DefaultPage") private var defaultPage: TabBarItem = TabBarItem.home
    @Published var currentTab: TabBarItem = TabBarItem.home
    
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
    @Published var showSelectLocation = false
    @Published var changeSection_Cal: Section_Cal? = nil
    @Published var changeSection: Section? = nil
    @Published var insertToCal: Cal? = nil
    @Published var insertIndex: Int? = nil
    
    //Change Location
    @Published var showChangeLocation = false
    @Published var changeLocation: Location? = nil
    
    //For Map Page
    @Published var showLocationEventList = false
    @Published var location: Location? = nil
    @Published var searchEventNameMap: String = ""
    
    //For Planning page
    @Published var highlightedEC: Event_Cal? = nil
    @Published var highlightedSC: Section_Cal? = nil
    
    //For Stat page
    @Published var selectedEvent: Event? = nil
    @Published var searchEventName: String = ""
    
    init(){
        currentTab = defaultPage
    }
}
