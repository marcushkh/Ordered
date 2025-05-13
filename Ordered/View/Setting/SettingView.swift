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
                        
                        Button {
                            defaultPage = TabBarItem.sugg
                        } label: {
                            Text(TabBarItem.sugg.label)
                        }
                        
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
