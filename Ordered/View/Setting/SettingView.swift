//
//  SettingView.swift
//  Ordered
//
//  Created by Kai Hin Hung on 12/3/2025.
//

import SwiftUI

struct SettingView: View{
    @ObservedObject var viewModel: ContentViewModel

    @AppStorage("DayStartTime") private var dayStartTime: Int = 4
    @AppStorage("DefaultPage") private var defaultPage: TabBarItem = TabBarItem.quick
    
    var body: some View{
        
        List {
            Button {
                viewModel.currentTab = .library
            } label: {
                HStack {
                    Label("Library", systemImage: "square.grid.2x2")
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(.cPrimary)
            }

            VStack(alignment: .leading){
                
                HStack{
                    Text("Default Page")
                    Spacer()
                    
                    Menu {
                        Button {
                            defaultPage = TabBarItem.quick
                        } label: {
                            Text(TabBarItem.quick.label)
                        }
                        ForEach([TabBarItem.view, .library]) { page in
                            Button(page.label) { defaultPage = page }
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
