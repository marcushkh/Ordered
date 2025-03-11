//
//  WelcomeScreen2.swift
//  Ordered
//
//  Created by Kai Hin Hung on 4/3/2025.
//

import SwiftUI
import AVKit

struct WelcomeScreen2: View {
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        GeometryReader{ geo in
            VStack{
                VStack{
                    if let path = Bundle.main.path(forResource: colorScheme == .dark ? "Welcome2VidDark" : "Welcome2Vid", ofType: "mp4") {
                        let player = AVPlayer(url: URL(fileURLWithPath: path))
                        VideoPlayer(player: player)
                            .onAppear() {
                                player.play()
                            }
                            .onTapGesture {
                                player.play()
                            }
                    } else {
                        Text("Video not found")
                    }
                }
                .frame(width: geo.size.width * 0.9, height: geo.size.height*0.484)
                
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
