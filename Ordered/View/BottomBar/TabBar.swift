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
        Group {
            if #available(iOS 26.0, *) {
                tabItems
                    .glassEffect(
                        .regular
                            .tint(Color.color1.opacity(0.35))
                            .interactive(),
                        in: Capsule()
                    )
            } else {
                tabItems
                    .background(Color.color1.opacity(0.9), in: Capsule())
            }
        }
        .padding(.horizontal, K.horizontal_padding)
        .ignoresSafeArea()
    }

    private var tabItems: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), content: {
            ForEach([TabBarItem.home, TabBarItem.library, TabBarItem.plan, TabBarItem.statistic, TabBarItem.setting]) { item in
                let tabBarIcon = Image(systemName: viewModel.currentTab != item ? item.icon : item.icon + ".fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: K.small_size, height: K.small_size)
                    .symbolEffect(.bounce, value: viewModel.currentTab == item)
                
                VStack {
                    if item == .plan{
                        tabBarIcon
                            .showCase(order: 2, title: "This helps you plan and record \n your day with a few clicks", cornerRadius: 10, scale: 1.5) {
                                withAnimation {
                                    viewModel.currentTab = .plan
                                }
                            }
                    }
                    else if item == .statistic{
                        tabBarIcon
                            .showCase(order: 11, title: "You can view Your Daily Progress Here!!", cornerRadius: 10, scale: 1.5) {
                                withAnimation {
                                    viewModel.currentTab = .home
                                }
                            }
                    }
                    else{
                        tabBarIcon
                    }
                    
                    
                }
                .foregroundStyle(viewModel.currentTab != item ? .primary : Color(.color3))
                .onTapGesture {
                    withAnimation {
                        HapticFeedback.light()
                        viewModel.currentTab = item
                    }
                }
            }
        })
        .padding(.horizontal)
        .padding(.vertical)
    }
}


enum TabBarItem: String, CaseIterable, Identifiable {
    case home
    case library
    case sugg
    case plan
    case statistic
    case setting
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        
        case .home:
            return "house"
        case .library:
            return "square.grid.2x2"
        case .sugg:
            return "apple.intelligence"
        case .plan:
            return "list.bullet.indent"
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
        case .library:
            return "Library"
        case .sugg:
            return "AI Suggestion"
        case .plan:
            return "Plan"
        case .statistic:
            return "Statistic"
        case .setting:
            return "Setting"
        }
    }
}
