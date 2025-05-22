//
//  WelcomeVM.swift
//  Ordered
//
//  Created by Kai Hin Hung on 31/8/2024.
//

import Foundation
import SwiftUI

class WelcomeVM: ObservableObject{
    @Published var showSelectTime = false
    @Published var selectedEvent: Event? = nil
    
    @Published var morningEvents: [Event] = []
    @Published var scheduleEvents: [Event] = []
    @Published var personalEvents: [Event] = []
    @Published var nightEvents: [Event] = []
    
    //For Location
    @Published var location: Location?
    @Published var showPopup = false
    
}
