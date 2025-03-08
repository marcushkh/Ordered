//
//  WelcomeScreen2.swift
//  Ordered
//
//  Created by Kai Hin Hung on 4/3/2025.
//

import SwiftUI

struct WelcomeScreen2: View {
    var body: some View {
        GeometryReader{ geo in
            VStack{
                Image("Welcome2")
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width * 0.9)
                
                Text("Stack Your Events Like a Pro")
                    .font(.title)
                    .bold()
                    .padding()
                
                Text("You can build your schedule just like stacking legos. \nWith a few clicks, your schedule can be built in no time!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            }
            .frame(width: geo.size.width)
        }
    }
}
