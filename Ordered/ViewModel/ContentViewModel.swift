//
//  ContentViewModel.swift
//  Ordered
//
//  Created by Kai Hin Hung on 31/7/2024.
//

import SwiftUI

class ContentViewModel: ObservableObject{
    @Published var currentTab = TabBarItem.home
    
    @Published var showEventDetail = false
    @Published var eventDetail: Event_Cal? = nil
}
