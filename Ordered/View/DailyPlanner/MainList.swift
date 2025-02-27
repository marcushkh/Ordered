//
//  MainList.swift
//  Ordered
//
//  Created by Kai Hin Hung on 15/8/2024.
//

import SwiftUI

struct MainList: View {
    @ObservedObject var viewModel: ContentViewModel
    @ObservedObject var dayPlannerVM: DayPlannerViewModel
    
    var body: some View {
        GeometryReader{geo in
            SwipeableStack(dayPlannerVM.dates(), jumpTo: dayPlannerVM.currentDate) { d, pos in
                OneDay(date: d, pos: pos, viewModel: viewModel, dayPlannerVM: dayPlannerVM)
            }
            .onChange(of: dayPlannerVM.currentDate, { oldValue, newValue in
                print(dayPlannerVM.currentDate)
            })
            .frame(height: geo.size.height)
        }
    }
}
