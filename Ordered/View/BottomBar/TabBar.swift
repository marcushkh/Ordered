//
//  TabBar.swift
//  Ordered
//
//  Created by Kai Hin Hung on 29/7/2024.
//

import SwiftUI

struct TabBar: View {
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View {
        
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), content: {
            ForEach([TabBarItem.home, TabBarItem.plan, TabBarItem.map, TabBarItem.statistic, TabBarItem.setting]) { item in
                let tabBarIcon = Image(systemName: viewModel.currentTab != item ? item.icon : item.icon + ".fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: K.small_size, height: K.small_size)
                            .symbolEffect(.bounce, value: viewModel.currentTab == item)
                
                VStack {
                    if item == .plan{
                        tabBarIcon
                            .showCase(order: 1,
                                      title: "This helps you plan and record \n your day with a few clicks",
                                      cornerRadius: 10,
                                      scale: 1.5)
                    }
                    else if item == .map{
                        tabBarIcon
                            .showCase(order: 2,
                                      title: "Modify the active places\nYou can also start event easily here",
                                      cornerRadius: 10,
                                      scale: 1.5)
                    }
                    else{
                        tabBarIcon
                    }
                    
                    
                }
                .foregroundStyle(viewModel.currentTab != item ? .primary : Color(.color3))
                .onTapGesture {
                    withAnimation {
                        viewModel.currentTab = item
                    }
                }
            }
        })
        .padding(.horizontal)
        .padding(.vertical)
        .background(.color1.opacity(0.9))
        .clipShape(Capsule())
        .padding(.horizontal, K.horizontal_padding)
        .ignoresSafeArea()
    }
}


enum TabBarItem: String, CaseIterable, Identifiable {
    case home
    case sugg
    case plan
    case map
    case statistic
    case setting
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        
        case .home:
            return "house"
        case .sugg:
            return "apple.intelligence"
        case .plan:
            return "list.bullet.indent"
        case .map:
            return "map"
        case .statistic:
            return "chart.bar"
        case .setting:
            return "gearshape"
        }
    }
    
    var label: String {
        switch self {
        case .home:
            return "Home"
        case .sugg:
            return "AI Suggestion"
        case .plan:
            return "Plan"
        case .map:
            return "Map"
        case .statistic:
            return "Statistic"
        case .setting:
            return "Setting"
        }
    }
}
