//
//  TabBar.swift
//  Ordered
//
//  Created by Kai Hin Hung on 29/7/2024.
//

import SwiftUI

struct TabBar: View {
    @StateObject var viewModel: ContentViewModel
    
    var body: some View {
        
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), content: {
            ForEach(TabBarItem.allCases) { item in
                
                VStack {
                    Image(systemName: viewModel.currentTab != item ? item.icon : item.icon + ".fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: K.small_size, height: K.small_size)
                        .symbolEffect(.bounce, value: viewModel.currentTab == item)
                    
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
        .background(.color1.opacity(0.75))
        .clipShape(Capsule())
        .padding(.horizontal, K.horizontal_padding)
        .ignoresSafeArea()
    }
}


#Preview {
    VStack{
        Spacer()
        TabBar(viewModel: ContentViewModel())
        
    }
    
}

enum TabBarItem: String, CaseIterable, Identifiable {
    case today
    case plan
    case startNow
    case statistic
    case setting
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .today:
            return "house"
        case .plan:
            return "list.clipboard"
        case .startNow:
            return "play.circle"
        case .statistic:
            return "chart.bar"
        case .setting:
            return "gearshape"
        }
    }
    
    var label: String {
        switch self {
        case .today:
            return "Home"
        case .plan:
            return "Plan"
        case .startNow:
            return "Start"
        case .statistic:
            return "Statistic"
        case .setting:
            return "Setting"
        }
    }
}
