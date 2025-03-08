//
//  WelcomeScreen4.swift
//  Ordered
//
//  Created by Kai Hin Hung on 4/3/2025.
//
import SwiftUI

struct WelcomeScreen4: View {
    var body: some View {
        GeometryReader{ geo in
            VStack{
                Image("Welcome4")
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width * 0.9)
                
                Text("Your Privacy Matters to Us")
                    .font(.title)
                    .bold()
                    .padding()
                
                Text("All data are Stored Locally")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                
                Text("iCloud can be used for backup and synchronization")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            }
            .frame(width: geo.size.width)
        }
    }
}
