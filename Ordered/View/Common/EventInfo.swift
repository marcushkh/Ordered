//
//  EventInfo.swift
//  Ordered
//
//  Created by Kai Hin Hung on 22/8/2024.
//

import SwiftUI

struct EventInfo: View {
    
    @ObservedObject var e: Event
    var showsIconBackground = false
    
    var body: some View {
        HStack{
            ZStack {
                if showsIconBackground {
                    Circle()
                        .fill(.cBackground)
                        .frame(height: K.xlarge_size)
                }

                Text(e.icon ?? "")
                    .font(showsIconBackground ? .title3 : .title)
            }
            
            Text(e.name ?? "")
                .font(.title3)
            Spacer()
        }
    }
}
