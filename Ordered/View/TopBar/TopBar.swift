//
//  TopBar.swift
//  Ordered
//
//  Created by Kai Hin Hung on 29/7/2024.
//

import SwiftUI

struct TopBar: View {
    @ObservedObject var viewModel: ContentViewModel
    @ObservedObject var dayPlannerVM: DayPlannerViewModel
    
    var body: some View {
        
        VStack(spacing: 0){
            if viewModel.currentTab == .home{
                homeTopBar
                    .padding(.horizontal, K.horizontal_padding)
            }
            else if viewModel.currentTab == .statistic{
                StatTopBar(dayPlannerVM: dayPlannerVM)
            }
        }
        .frame(width: UIScreen.main.bounds.width)
        .background(.color1, ignoresSafeAreaEdges: .top)
        
        
        if viewModel.currentTab == .home || viewModel.currentTab == .plan{
            WeekBar(viewModel: viewModel, dayPlannerVM: dayPlannerVM)
                .padding(.horizontal, K.horizontal_padding)
                .padding(.bottom, K.xxxsmall_size)
                .background(.color1)
                .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 30, bottomTrailingRadius: 30))
        }
        else{
            UnevenRoundedRectangle(bottomLeadingRadius: 30, bottomTrailingRadius: 30)
                .fill(.color1)
                .frame(width: UIScreen.main.bounds.size.width, height: K.horizontal_padding)
        }
    }
    
    var homeTopBar: some View{
        VStack{
            //two icon + theme of day
            HStack{
                
                Button{
                    
                } label: {
                    Image(systemName: "calendar")
                        .resizable()
                        .scaledToFit()
                        .frame(height: K.xsmall_size)
                        .foregroundStyle(.color3)
                }
                
                Spacer()
                
                
                Text(dayPlannerVM.currentDate.monthYYYY())
                    .font(.title2)
                    .bold()
                    .onTapGesture {
                        dayPlannerVM.setCurrentDate(to: Date.now)
                    }
                
                
                Spacer()
                
                Button {
                    
                } label: {
                    Image(systemName: "exclamationmark.triangle")
                        .resizable()
                        .scaledToFit()
                        .frame(height: K.xsmall_size)
                        .foregroundStyle(.color3)
                }
            }
            .padding(.vertical)
        }
    }
}



#Preview {
    VStack(spacing: 0){
        TopBar(viewModel: ContentViewModel(), dayPlannerVM: DayPlannerViewModel())
        Spacer()
    }
    
}
