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
    
    @Environment(\.colorScheme) var colorScheme
    
    @State var selectedDate: Date = Date.now
    @State var showClear: Bool = false
    
    var body: some View {
        
        VStack(spacing: 0){
            if viewModel.currentTab == .home || viewModel.currentTab == .weeklyDefault{
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
        else if viewModel.currentTab == .weeklyDefault{
            WeekDefaultTopBar(viewModel: viewModel)
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
    
    enum TopBarCases: String, CaseIterable, Identifiable{
        case home
        case weekDefaultWithSelectedDay
        case weekDefaultWithoutSelectedDay
        
        var id: String { self.rawValue }
    }
    
    var currentCase: TopBarCases{
        if viewModel.currentTab == .home{
            return .home
        }
        if viewModel.currentTab == .weeklyDefault{
            if viewModel.selectedWeekAb == nil{
                return .weekDefaultWithoutSelectedDay
            }
            else{
                return .weekDefaultWithSelectedDay
            }
        }
        return .home
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
                
                if currentCase == .home{
                    Text(dayPlannerVM.currentDate.monthYYYY())
                        .font(.title2)
                        .bold()
                        .onTapGesture {
                            dayPlannerVM.setCurrentDate(to: Date.now)
                        }
                }
                if currentCase == .weekDefaultWithSelectedDay || currentCase == .weekDefaultWithoutSelectedDay{
                    Text("Weekly Default")
                        .font(.title2)
                        .bold()
                }
                
                
                Spacer()
                
                Menu {
                    if currentCase == .home{ // && not yet imported
                        Button{
                            var cal = Cal.get(date: dayPlannerVM.currentDate) ?? Cal.new(date: dayPlannerVM.currentDate)
                            cal.setWeeklyDefault()
                        } label: {
                            Text("Use Week Default")
                            Image(systemName: "list.clipboard")
                        }
                    }
                    
                    if viewModel.highlightedEC != nil{
                        Button {
                            withAnimation {
                                viewModel.highlightedEC?.toNewSection(colorScheme: colorScheme)
                                viewModel.refresh.toggle()
                            }
                        } label: {
                            Text("Start New Section")
                            Image(systemName: "folder")
                        }
                    }
                    
                    var clearText: String {
                        switch currentCase {
                        case .home:
                            "Clear Unfinished Events"
                        case .weekDefaultWithSelectedDay:
                            "Clear " + String(Date.intToFullName(viewModel.selectedWeekAb!))
                        case .weekDefaultWithoutSelectedDay:
                            "Clear All Weekly Default"
                        }
                    }
                    Button(role: .destructive) {
                        showClear = true
                    } label: {
                        
                        Text(clearText)
                        Image(systemName: "paintbrush")
                            .rotationEffect(Angle(degrees: 180))
                    }
                    
                } label: {
                    ZStack{
                        Rectangle()
                            .fill(Color.color1)
                        
                        Image(systemName: "ellipsis")
                            .resizable()
                            .scaledToFit()
                            .frame(width: K.xsmall_size, height: K.xsmall_size)
                            .foregroundStyle(.color3)
                            .padding(.trailing, 4)
                    }
                    .frame(width: K.xsmall_size, height: K.xsmall_size)
                }
                
            }
            .padding(.vertical)
            .alert(isPresented: $showClear) {
                if currentCase == .home{
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
                else if currentCase == .weekDefaultWithSelectedDay{//viewModel.currentTab == .weeklyDefault
                    Alert(  title: Text("CLEAR Weekly Default for " + String(Date.intToFullName(viewModel.selectedWeekAb!))),
                            message: Text("Are you sure to REMOVE ALL events and section for " + String(Date.intToFullName(viewModel.selectedWeekAb!))),
                            primaryButton: .destructive(Text("Clear")) {
                                withAnimation {
                                    // Remove all Week Default
                                    WeekDefault.get(viewModel.selectedWeekAb!)?.delete()
                                    viewModel.refresh.toggle()
                                }
                            },
                            secondaryButton: .cancel())
                }
                else{
                    Alert(  title: Text("CLEAR ALL Weekly Default"),
                            message: Text("Are you sure to REMOVE ALL events and section for ALL WEEKDAYS?"),
                            primaryButton: .destructive(Text("Clear")) {
                                withAnimation {
                                    // Remove all Week Default
                                    for i in Range(0...6){
                                        WeekDefault.get(i)?.delete()
                                    }
                                    viewModel.refresh.toggle()
                                }
                            },
                            secondaryButton: .cancel())
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 0){
        TopBar(viewModel: ContentViewModel(), dayPlannerVM: DayPlannerViewModel())
        Spacer()
    }
    
}
