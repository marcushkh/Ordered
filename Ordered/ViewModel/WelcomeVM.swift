//
//  WelcomeVM.swift
//  Ordered
//
//  Created by Kai Hin Hung on 31/8/2024.
//

import Foundation
import SwiftUI

class WelcomeVM: ObservableObject{
    @Published var showAlert = false
    @Published var alertMessage = ""
}
