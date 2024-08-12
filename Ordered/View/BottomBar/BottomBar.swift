//
//  TabBar.swift
//  Ordered
//
//  Created by Kai Hin Hung on 29/7/2024.
//

import SwiftUI

struct BottomBar: View {
    
    @StateObject var viewModel: ContentViewModel
    
    var body: some View {
        if [TabBarItem.today, TabBarItem.statistic, TabBarItem.setting].contains(viewModel.currentTab){
            TabBar(viewModel: viewModel)
        }
        else if viewModel.currentTab == .plan{
            EventBar()
        }
    }
}

#Preview {
    VStack{
        Spacer()
        BottomBar(viewModel: ContentViewModel())
        
    }
    
}

