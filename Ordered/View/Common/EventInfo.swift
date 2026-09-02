//
//  EventInfo.swift
//  Ordered
//
//  Created by Kai Hin Hung on 22/8/2024.
//

import SwiftUI

struct EventInfo: View {
    
    @ObservedObject var e: Event
    
    var body: some View {
        HStack{
            Text(e.icon ?? "")
                .font(.title) 
            
            Text(e.name ?? "")
                .font(.title3)
            Spacer()
        }
    }
}
