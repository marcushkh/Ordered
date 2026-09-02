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
        if viewModel.currentTab != .statistic {
            ZStack{
                
                VStack{
                    VStack(spacing: 0){
                        if viewModel.currentTab == .home{
                            homeTopBar
                                .padding(.horizontal, K.horizontal_padding)
                        }
                        else if viewModel.currentTab == .setting{
                            SettingTopBar(viewModel: viewModel)
                        }
                    }
                    
                    //            .background(.color1, ignoresSafeAreaEdges: .top)
                    
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
            }
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
                            .frame(width: K.xxl_size, height: K.xxl_size)
                    }
                    .onChange(of: selectedDate) { oldValue, newValue in
                        HapticFeedback.light()
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
                        HapticFeedback.light()
                        dayPlannerVM.setCurrentDate(to: MyCalendar.getToday())
                    }
                
                Spacer()

                Image(systemName: "paintbrush")
                    .resizable()
                    .scaledToFit()
                    .bold()
                    .rotationEffect(Angle(degrees: 180))
                    .frame(height: K.small_size)
                    .foregroundStyle(.color3)
                    .onTapGesture {
                        HapticFeedback.heavy()
                        showClear = true
                    }
                    .showCase(order: 6, title: "Clear All Events", cornerRadius: 10, scale: 1.5) {
                        withAnimation {
                            HapticFeedback.heavy()
                            Cal.clear(date: dayPlannerVM.currentDate)
                            Cal.get(date: dayPlannerVM.currentDate)?.removeAllEmptyEvents()
                            viewModel.refresh.toggle()
                        }
                    }
                
//                Image(systemName: "list.triangle")
//                    .resizable()
//                    .scaledToFit()
//                    .frame(height: K.xxsmall_size)
//                    .foregroundStyle(.color3)
//                    .onTapGesture {
//                        withAnimation {
//                            viewModel.currentTab = .plan
//                        }
//                    }
            }
            // 40pt controls plus 8pt padding on each side preserve the previous
            // 24pt icon plus 16pt padding on each side overall height.
            .padding(.vertical, 8)
            .alert(isPresented: $showClear) {
                Alert(  title: Text("CLEAR the Unfinished Events"),
                        message: Text("Are you sure to remove all events and sections in this day that are not started or finished?"),
                        primaryButton: .destructive(Text("Clear")) {
                    withAnimation {
                        HapticFeedback.heavy()
                        Cal.clear(date: dayPlannerVM.currentDate)
                        Cal.get(date: dayPlannerVM.currentDate)?.removeAllEmptyEvents()
                        viewModel.refresh.toggle()
                    }
                },
                        secondaryButton: .cancel())
            }
        }
    }
}
