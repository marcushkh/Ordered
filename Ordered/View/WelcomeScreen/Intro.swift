//
//  Intro.swift
//  Ordered
//
//  Created by Kai Hin Hung on 23/5/2025.
//
import SwiftUI

struct Intro: View{
    
    var body: some View{
        GeometryReader{ geo in
            VStack{
                Image("Welcome1")
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width * 0.9)
                
                Text("Are you ready to make your life ordered again?")
                    .font(.title)
                    .bold()
                    .padding()
                    .multilineTextAlignment(.center)
                
                Text("This app lets you plan and record \n every single event in your day")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}
