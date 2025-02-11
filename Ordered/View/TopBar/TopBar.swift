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
        //TODO: Change the Top Bar Content depending on the Tab View
        
        VStack(spacing: 0){
            if viewModel.currentTab == .home{
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
                                //TODO: Finish this
//                                dayPlannerVM.setCurrentDate(to: Date())
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
        .padding(.horizontal, K.horizontal_padding)
        .frame(width: UIScreen.main.bounds.width)
        .background(.color1, ignoresSafeAreaEdges: .top)
        
        
        if viewModel.currentTab == .home || viewModel.currentTab == .plan{
            
            WeekBar(viewModel: viewModel, dayPlannerVM: dayPlannerVM)
                .padding(.horizontal, K.horizontal_padding)
                .padding(.bottom, K.xxxsmall_size)
                .background(.color1)
                .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 40, bottomTrailingRadius: 40))
        }
    }
}



#Preview {
    VStack(spacing: 0){
        TopBar(viewModel: ContentViewModel(), dayPlannerVM: DayPlannerViewModel())
        Spacer()
    }
    
}
