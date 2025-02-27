//
//  File.swift
//  Ordered
//
//  Created by Kai Hin Hung on 25/2/2025.
//

import SwiftUI

struct CustomEvent: Codable, Hashable{
    var color: String
    var name: String
    var icon: String
    var objectId: URL
    
    var duration: Int?
    var startTime: String?
    var endTime: String?
    
    var aStartTime: String?
    var durationFinished: Int?
}
