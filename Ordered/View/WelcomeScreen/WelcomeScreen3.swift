//
//  WelcomeScreen3.swift
//  Ordered
//
//  Created by Kai Hin Hung on 4/3/2025.
//

import SwiftUI
struct WelcomeScreen3: View {
    var body: some View {
        GeometryReader{ geo in
            VStack{
                Image("Welcome3")
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width * 0.7, height: geo.size.height*0.484)
                    .shadow(color: .cPrimary, radius: 40)
                    .padding(.top)
                
                Text("Live Activity and\nDynamic Island Support")
                    .font(.title)
                    .bold()
                    .multilineTextAlignment(.center)
                    .padding()
                
                Text("Without going into the app\nYou can Select, Start and Finish an Event!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(width: geo.size.width)
        }
    }
}
