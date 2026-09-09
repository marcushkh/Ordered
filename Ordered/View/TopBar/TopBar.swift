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
    @ObservedObject var statViewModel: StatViewModel
    
    @Environment(\.colorScheme) var colorScheme
    
    @State var selectedDate: Date = MyCalendar.getToday()
    @State var showClear: Bool = false
    @State private var showCalendar = false
    
    var body: some View {
        VStack(spacing: 0){
            VStack(spacing: 0){
                if viewModel.currentTab == .home{
                    homeTopBar
                        .padding(.horizontal, K.horizontal_padding)
                        .background(.color1, ignoresSafeAreaEdges: .top)
                }
                else if viewModel.currentTab == .quick{
                    QuickFinishTopBar(
                        viewModel: viewModel,
                        dayPlannerVM: dayPlannerVM
                    )
                    .padding(.horizontal, K.horizontal_padding)
                    .background {
                        UnevenRoundedRectangle(
                            bottomLeadingRadius: 30,
                            bottomTrailingRadius: 30
                        )
                        .fill(.color1)
                        .ignoresSafeArea(edges: .top)
                    }
                }
                else if viewModel.currentTab == .statistic{
                    StatTopBar(viewModel: statViewModel, dayPlannerVM: dayPlannerVM)
                        .background {
                            UnevenRoundedRectangle(
                                bottomLeadingRadius: 30,
                                bottomTrailingRadius: 30
                            )
                            .fill(.color1)
                            .ignoresSafeArea(edges: .top)
                        }
                }
                else if viewModel.currentTab == .setting{
                    SettingTopBar(viewModel: viewModel)
                }
            }
            .zIndex(1)
            
            if [TabBarItem.home, TabBarItem.plan].contains(viewModel.currentTab){
                WeekBar(viewModel: viewModel, dayPlannerVM: dayPlannerVM)
                    .padding(.horizontal, K.horizontal_padding)
                    .padding(.vertical, K.xxxsmall_size)
                    .background {
                        UnevenRoundedRectangle(
                            bottomLeadingRadius: 30,
                            bottomTrailingRadius: 30
                        )
                        .fill(.color1)
                        .ignoresSafeArea(edges: .top)
                    }
                    .zIndex(1)
                
            }
            UnevenRoundedRectangle(bottomLeadingRadius: 30, bottomTrailingRadius: 30)
                .fill(.color1)
                .frame(width: UIScreen.main.bounds.size.width, height: K.horizontal_padding)
                .padding(.top, -20)
                .zIndex(0)
        }
        
    }
    
    var homeTopBar: some View{
        
        VStack{
            // Clear, date selection, and library.
            HStack{
                Button {
                    HapticFeedback.heavy()
                    showClear = true
                } label: {
                    Image(systemName: "paintbrush")
                        .resizable()
                        .scaledToFit()
                        .bold()
                        .rotationEffect(Angle(degrees: 180))
                        .frame(height: K.small_size)
                        .foregroundStyle(.color3)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear Unfinished Events")
                .showCase(order: 6, title: "Clear Unfinished Events", cornerRadius: 10, scale: 1.5) {
                    withAnimation {
                        HapticFeedback.heavy()
                        Cal.clear(date: dayPlannerVM.currentDate)
                        Cal.get(date: dayPlannerVM.currentDate)?.removeAllEmptyEvents()
                        viewModel.refresh.toggle()
                    }
                }
                
                Spacer()

                Button {
                    HapticFeedback.light()
                    selectedDate = dayPlannerVM.currentDate
                    showCalendar = true
                } label: {
                    Text(dayPlannerVM.currentDate.monthYYYY())
                        .font(.title2)
                        .bold()
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Choose a date")
                .popover(isPresented: $showCalendar) {
                    DatePicker("Choose a date", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .tint(.color4)
                        .frame(width: 320)
                        .padding()
                        .presentationCompactAdaptation(.popover)
                        .onChange(of: selectedDate) { _, newValue in
                            HapticFeedback.light()
                            dayPlannerVM.setCurrentDate(to: newValue)
                            showCalendar = false
                        }
                }

                Spacer()

                Button {
                    HapticFeedback.light()
                    viewModel.isShowLibrary = true
                } label: {
                    Image(systemName: "square.grid.2x2")
                        .resizable()
                        .scaledToFit()
                        .frame(width: K.small_size, height: K.small_size)
                        .foregroundStyle(.color3)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Library")
            }
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

struct QuickFinishTopBar: View {
    @ObservedObject var viewModel: ContentViewModel
    @ObservedObject var dayPlannerVM: DayPlannerViewModel

    @State private var selectedDate = MyCalendar.getToday()

    var body: some View {
        HStack {
            Color.clear
                .frame(width: 44, height: 44)
            Spacer()
            Text("Finish Now!")
                .font(.title2)
                .bold()

            Spacer()

            Button {
                HapticFeedback.light()
                viewModel.showQuickFinishEditor = true
            } label: {
                Image(systemName: "pencil")
                    .font(.title3)
                    .foregroundStyle(.color3)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit Quick Finish")
        }
        .padding(.vertical, 8)
        .onAppear {
            selectedDate = dayPlannerVM.currentDate
        }
        .onChange(of: selectedDate) { _, newValue in
            HapticFeedback.light()
            dayPlannerVM.setCurrentDate(to: newValue)
        }
        .onChange(of: dayPlannerVM.currentDate) { _, newValue in
            selectedDate = newValue
        }
    }
}
