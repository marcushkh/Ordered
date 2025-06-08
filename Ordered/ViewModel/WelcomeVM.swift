//
//  WelcomeVM.swift
//  Ordered
//
//  Created by Kai Hin Hung on 31/8/2024.
//

import Foundation
import SwiftUI

class WelcomeVM: ObservableObject{
    //For Location
    @Published var location: Location?
    @Published var showPopup = false
    
    @Published var showAlert = false
    @Published var alertMessage = ""
}
