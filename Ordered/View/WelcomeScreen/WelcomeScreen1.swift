//
//  WelcomeScreen1.swift
//  Ordered
//
//  Created by Kai Hin Hung on 4/3/2025.
//


import SwiftUI
struct WelcomeScreen1: View {
    var body: some View {
        GeometryReader{ geo in
            VStack{
                Image("Welcome1")
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width * 0.9)
                
                Text("Plan and Record Your Day")
                    .font(.title)
                    .bold()
                    .padding()
                
                Text("Make Your Life Ordered Again!\nReclaim Control Over Your Day!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            }
            .frame(width: geo.size.width)
        }
        
    }
}
