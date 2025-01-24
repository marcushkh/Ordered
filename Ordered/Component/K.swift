//
//  K.swift
//  Ordered
//
//  Created by Kai Hin Hung on 1/8/2024.
//

import Foundation
import SwiftUI

enum K{
    static let horizontal_padding = 20.0
    static let vertical_padding = 16.0
    
    static let xxxsmall_size = 8.0
    static let xxsmall_size = 16.0
    static let xsmall_size = 20.0
    static let small_size = 24.0
    static let medium_size = 28.0
    static let large_size = 32.0
    static let xlarge_size = 36.0
    
    static let defaultSectionColor = [
        "DCEDFA",
        "D2CAF3",
        "E3BCB5",
        "F0DCB8",
        "FDFBCC",
        "E6EEDA"
    ]
    
    static let defaultSection = ["Morning Routine", "Schedule", "Personal Time", "Night Routine"]
    
    static let allEvents : [Event] = [
        Event.save(icon: "☀️", name: "Wake Up", duration: -1),//0
        Event.save(icon: "🪥", name: "Brush", duration: -1),
        Event.save(icon: "🛏️", name: "Make Bed", duration: -1),
        Event.save(icon: "☕️", name: "Coffee", duration: -1),
        Event.save(icon: "🍽️", name: "Breakfast", duration: -1),
        Event.save(icon: "🧠", name: "Meditation", duration: 30),//5
        Event.save(icon: "🏃‍♂️", name: "Exercise", duration: 30),
        Event.save(icon: "🚿", name: "Shower", duration: -1),
        Event.save(icon: "💼", name: "Work", duration: -1),
        Event.save(icon: "🏫", name: "School", duration: -1),
        Event.save(icon: "🚀", name: "Personal Project", duration: -1),//10
        Event.save(icon: "📚", name: "Learning", duration: -1),
        Event.save(icon: "🚀", name: "Business Idea", duration: -1),
        Event.save(icon: "📖", name: "Reading", duration: -1),
        Event.save(icon: "💆‍♀️", name: "Skin Care", duration: -1),
        Event.save(icon: "📝", name: "Planning For Next Day", duration: -1),
        Event.save(icon: "🥱", name: "Sleep", duration: -1)
        
    ]
    
    static let morningRoutineDefault = [allEvents[0], allEvents[1], allEvents[2], allEvents[3], allEvents[4], allEvents[5],  allEvents[6], allEvents[7]]
    
    static let scheduleDefault = [allEvents[8], allEvents[9], allEvents[10]]
    
    static let personalDefault = [allEvents[10], allEvents[12], allEvents[6], allEvents[11], allEvents[13]]
    
    static let nightRoutineDefault = [allEvents[7], allEvents[1], allEvents[13], allEvents[14], allEvents[5], allEvents[15], allEvents[16]]
    
    static let presentationCornerRadius: CGFloat = 30
}
//Pixels: 24
