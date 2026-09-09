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
        HStack(spacing: 0) {
            ForEach([TabBarItem.home, TabBarItem.plan, TabBarItem.quick, TabBarItem.statistic, TabBarItem.setting]) { item in
                let tabBarIcon = Image(systemName: viewModel.currentTab == item ? item.selectedIcon : item.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: K.small_size, height: K.small_size)
                    .symbolEffect(.bounce, value: viewModel.currentTab == item)

                Button {
                    withAnimation {
                        HapticFeedback.light()
                        viewModel.currentTab = item
                    }
                } label: {
                    VStack(spacing: 4) {
                        Group {
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

                        Text(item.label)
                            .font(.caption2)
                            .fontWeight(viewModel.currentTab == item ? .semibold : .regular)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundStyle(viewModel.currentTab == item ? Color.color3 : Color.primary)
                    .frame(maxWidth: .infinity, minHeight: 58)
                    .contentShape(Rectangle())
                    .padding(4)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(4)
        .contentShape(Capsule())
    }
}


enum TabBarItem: String, CaseIterable, Identifiable {
    case home
    case quick
    case plan
    case statistic
    case setting
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        
        case .home:
            return "house"
        case .quick:
            return "checkmark.circle"
        case .plan:
            return "list.bullet.indent"
        case .statistic:
            return "chart.bar"
        case .setting:
            return "gearshape"
        }
    }

    var selectedIcon: String {
        switch self {
        case .home:
            return "house.fill"
        case .quick:
            return "checkmark.circle.fill"
        case .plan:
            return "list.bullet.indent"
        case .statistic:
            return "chart.bar.fill"
        case .setting:
            return "gearshape.fill"
        }
    }
    
    var label: String {
        switch self {
        case .home:
            return "Home"
        case .quick:
            return "Quick Finish"
        case .plan:
            return "Plan"
        case .statistic:
            return "Statistic"
        case .setting:
            return "Setting"
        }
    }
}
