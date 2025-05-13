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
        if viewModel.currentTab != .plan{
            TabBar(viewModel: viewModel)
        }
    }
}
