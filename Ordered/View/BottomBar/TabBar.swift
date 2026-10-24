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
            ForEach([TabBarItem.quick, TabBarItem.view, TabBarItem.library, TabBarItem.statistic, TabBarItem.setting]) { item in
                let tabBarIcon = Image(systemName: viewModel.currentTab == item ? item.selectedIcon : item.icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: K.small_size, height: K.small_size)
                    .symbolEffect(.bounce, value: viewModel.currentTab == item)

                Button {
                    guard viewModel.currentTab != item else { return }
                    HapticFeedback.light()
                    viewModel.currentTab = item
                    viewModel.tutorial.openedTab(item.rawValue)
                } label: {
                    VStack(spacing: 4) {
                        tabBarIcon
                    }
                    .foregroundStyle(viewModel.currentTab == item ? Color.color3 : Color.primary)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
                    .padding(.horizontal, 4)
                }
                .showCase(.completedTab, enabled: item == .view)
                .showCase(.libraryTab, enabled: item == .library)
                .showCase(.statisticsTab, enabled: item == .statistic)
                .accessibilityLabel(item.label)
                .accessibilityAddTraits(viewModel.currentTab == item ? .isSelected : [])
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(4)
        .contentShape(Capsule())
    }
}


enum TabBarItem: String, CaseIterable, Identifiable {
    case view
    case quick
    case library
    case statistic
    case setting
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        
        case .view:
            return "list.triangle"
        case .quick:
            return "house"
        case .library:
            return "books.vertical"
        case .statistic:
            return "chart.bar"
        case .setting:
            return "gearshape"
        }
    }

    var selectedIcon: String {
        switch self {
        case .view:
            return "list.triangle"
        case .quick:
            return "house.fill"
        case .library:
            return "books.vertical.fill"
        case .statistic:
            return "chart.bar.fill"
        case .setting:
            return "gearshape.fill"
        }
    }
    
    var label: String {
        switch self {
        case .view:
            return "View"
        case .quick:
            return "Home"
        case .library:
            return "Library"
        case .statistic:
            return "Statistic"
        case .setting:
            return "Setting"
        }
    }
}
