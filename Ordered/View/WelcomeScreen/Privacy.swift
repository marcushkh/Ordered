//
//  Privacy.swift
//  Ordered
//
//  Created by Kai Hin Hung on 22/5/2025.
//

import SwiftUI

struct Privacy: View {
    var body: some View {
        GeometryReader{ geo in
            VStack{
                Image("Privacy")
                    .resizable()
                    .scaledToFit()
                    .frame(width: geo.size.width * 0.9)
                
                Text("Your Privacy Matters")
                    .font(.title)
                    .bold()
                    .padding()
                    .multilineTextAlignment(.center)
                
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
