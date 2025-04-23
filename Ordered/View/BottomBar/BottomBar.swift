//
//  TabBar.swift
//  Ordered
//
//  Created by Kai Hin Hung on 29/7/2024.
//

import SwiftUI

struct BottomBar: View {
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View {
        if [TabBarItem.home, TabBarItem.map, TabBarItem.statistic, TabBarItem.setting].contains(viewModel.currentTab){
            TabBar(viewModel: viewModel)
        }
    }
}
