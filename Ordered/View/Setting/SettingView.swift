//
//  SettingView.swift
//  Ordered
//
//  Created by Kai Hin Hung on 12/3/2025.
//

import SwiftUI

struct SettingView: View{
    @AppStorage("DayStartTime") private var dayStartTime: Int = 4
    @AppStorage("mapStyle") private var mapStyle: MapStyle = MapStyle.grid
    @AppStorage("DefaultPage") private var defaultPage: TabBarItem = TabBarItem.home
    
    var body: some View{
        
        List {
            #if DEBUG
            // Movement Detection Debug Info
            VStack(alignment: .leading, spacing: 8) {
                Text("Movement Detection (Debug)")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                MovementDebugView()
            }
            .padding(.vertical, 8)
            #endif
            
            VStack(alignment: .leading){
                
                HStack{
                    Text("Default Page")
                    Spacer()
                    
                    Menu {
                        Button {
                            defaultPage = TabBarItem.home
                        } label: {
                            Text(TabBarItem.home.label)
                        }
                        
//                        Button {
//                            defaultPage = TabBarItem.sugg
//                        } label: {
//                            Text(TabBarItem.sugg.label)
//                        }
                        
                        Button {
                            defaultPage = TabBarItem.map
                        } label: {
                            Text(TabBarItem.map.label)
                        }
                        
                    } label: {
                        HStack{
                            Text(defaultPage.label)
                            Image(systemName: "chevron.down")
                                .font(.footnote)
                        }
                        .foregroundStyle(.cPrimary)
                    }
                }
            }
            
            VStack(alignment: .leading){
                HStack{
                    Text("Map Style")
                    Spacer()
                    
                    Menu {
                        Button {
                            mapStyle = MapStyle.grid
                        } label: {
                            Text(MapStyle.grid.rawValue.capitalizedFirst)
                        }
                        
                        Button {
                            mapStyle = MapStyle.dots
                        } label: {
                            Text(MapStyle.dots.rawValue.capitalizedFirst)
                        }
                        
                    } label: {
                        HStack{
                            Text(mapStyle.rawValue.capitalizedFirst)
                            Image(systemName: "chevron.down")
                                .font(.footnote)
                        }
                        .foregroundStyle(.cPrimary)
                    }
                }
            }
            
            VStack(alignment: .leading){
                HStack{
                    Text("The start of your day")
                    
                    Spacer()
                    Menu {
                        Button {
                            dayStartTime = 0
                        } label: {
                            Text("Mid Night")
                        }
                        ForEach(1..<10, id: \.self){ num in
                            Button {
                                dayStartTime = num
                            } label: {
                                Text(String(num) + " am")
                                
                            }
                        }
                        
                    } label: {
                        HStack{
                            if dayStartTime == 12{
                                Text("Mid Night")
                            }
                            else{
                                Text(String(dayStartTime) + " am")
                            }
                            Image(systemName: "chevron.down")
                                .font(.footnote)
                        }
                        .foregroundStyle(.cPrimary)
                    }
                    
                }
                Text("Many night owls have schedule after midnight. \nChoose a time that’s a few hours after you usually go to sleep.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            
        }
    }
}

#if DEBUG
struct MovementDebugView: View {
    @StateObject var movementDetection = MovementDetection.shared
    @State private var currentTime = Date()
    @State private var timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("State:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(movementDetection.currentState == .stationary ? "Stationary" : "Transit")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(movementDetection.currentState == .stationary ? .red : .green)
            }
            
            if let startTime = movementDetection.lastMovementTimestamp {
                HStack {
                    Text("Since:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(formatTime(startTime))
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                if movementDetection.currentState == .stationary {
                    HStack {
                        Text("Duration:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(formatDuration(from: startTime, to: currentTime))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(from startTime: Date, to currentTime: Date) -> String {
        let duration = currentTime.timeIntervalSince(startTime)
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}
#endif
