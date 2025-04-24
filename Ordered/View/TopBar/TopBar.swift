//
//  TopBar.swift
//  Ordered
//
//  Created by Kai Hin Hung on 29/7/2024.
//

import SwiftUI
import ActivityKit

struct TopBar: View {
    @ObservedObject var viewModel: ContentViewModel
    @ObservedObject var dayPlannerVM: DayPlannerViewModel
    
    @Environment(\.colorScheme) var colorScheme
    
    @State var selectedDate: Date = MyCalendar.getToday()
    @State var showClear: Bool = false
    
    var body: some View {
        
        VStack(spacing: 0){
            if viewModel.currentTab == .home{
                homeTopBar
                    .padding(.horizontal, K.horizontal_padding)
            }
            else if viewModel.currentTab == .statistic{
                StatTopBar(viewModel: viewModel, dayPlannerVM: dayPlannerVM)
            }
        }
        .frame(width: UIScreen.main.bounds.width)
        .background(.color1, ignoresSafeAreaEdges: .top)
        
        
        if [TabBarItem.home, TabBarItem.plan].contains(viewModel.currentTab){
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
                Image(systemName: "calendar")
                    .resizable()
                    .scaledToFit()
                    .frame(height: K.xsmall_size)
                    .foregroundStyle(.color3)
                    .overlay {
                        DatePicker("", selection: $selectedDate, displayedComponents: .date)
                            .blendMode(.destinationOver)
                            .tint(.color4)
                            .frame(width: K.xsmall_size, height: K.xsmall_size)
                    }
                    .onChange(of: selectedDate) { oldValue, newValue in
                        dayPlannerVM.setCurrentDate(to: selectedDate)
                    }
                    .onChange(of: dayPlannerVM.currentDate) { oldValue, newValue in
                        selectedDate = dayPlannerVM.currentDate
                    }
                
                Spacer()
                
                Text(dayPlannerVM.currentDate.monthYYYY())
                    .font(.title2)
                    .bold()
                    .onTapGesture {
                        dayPlannerVM.setCurrentDate(to: MyCalendar.getToday())
                    }
                
                Spacer()

                Image(systemName: "paintbrush")
                    .bold()
                    .rotationEffect(Angle(degrees: 180))
                    .frame(height: K.small_size)
                    .foregroundStyle(.color3)
                    .onTapGesture {
                        showClear = true
                    }
                
                
            }
            .padding(.vertical)
            .alert(isPresented: $showClear) {
                Alert(  title: Text("CLEAR the Unfinished Events"),
                        message: Text("Are you sure to remove all events and section in this day that are not started or finished?"),
                        primaryButton: .destructive(Text("Clear")) {
                    withAnimation {
                        Cal.clear(date: dayPlannerVM.currentDate)
                        viewModel.refresh.toggle()
                    }
                },
                        secondaryButton: .cancel())
            }
        }
    }
}

