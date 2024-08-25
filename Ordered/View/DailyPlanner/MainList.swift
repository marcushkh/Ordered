//
//  MainList.swift
//  Ordered
//
//  Created by Kai Hin Hung on 15/8/2024.
//

import SwiftUI

struct MainList: View {
    @StateObject var viewModel: ContentViewModel
    @StateObject var dayPlannerVM: DayPlannerViewModel
    
    var body: some View {
        GeometryReader{geo in
            SwipeableStack(dayPlannerVM.dates(), jumpTo: dayPlannerVM.currentDate) { d, pos in
                OneDay(date: "20240825", pos: pos, viewModel: viewModel, dayPlannerVM: dayPlannerVM)
            }
            .frame(height: geo.size.height)
            
        }
        
    }
}

#Preview {
    MainList(viewModel: ContentViewModel(), dayPlannerVM: DayPlannerViewModel())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
