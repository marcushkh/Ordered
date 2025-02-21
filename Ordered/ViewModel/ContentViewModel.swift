//
//  ContentViewModel.swift
//  Ordered
//
//  Created by Kai Hin Hung on 31/7/2024.
//

import SwiftUI

class ContentViewModel: ObservableObject{
    @Published var refresh = false
    
    @Published var currentTab = TabBarItem.home
    
    @Published var showEventDetail = false
    @Published var eventDetail: Event_Cal? = nil
    @Published var editEvent_Cal: Event_Cal? = nil
    
    @Published var showCreateEvent = false
    @Published var createEvent_Section_Cal: Section_Cal? = nil
    
    @Published var showChangeSection = false
    @Published var changeSection_Cal: Section_Cal? = nil
    @Published var insertToCal: Cal? = nil
    @Published var insertIndex: Int? = nil
    
    //For Planning page
    @Published var highlightedEC: Event_Cal? = nil
    
    //For Weekly Default
    @Published var showEventBar: Bool = false
    @Published var selectedWeekAb: Int? = nil
    @Published var showWeekDetail: Bool = false
    @Published var insertToWeek: WeekDefault? = nil
    
    //For Stat page
    @Published var selectedEvent: Event? = nil
    @Published var searchEventName: String = ""
}
