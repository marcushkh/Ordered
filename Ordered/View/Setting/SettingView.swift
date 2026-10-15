//
//  SettingView.swift
//  Ordered
//
//  Created by Kai Hin Hung on 12/3/2025.
//

import SwiftUI

struct SettingView: View{
    @AppStorage("DayStartTime") private var dayStartTime = MyCalendar.defaultDayStartHour
    @AppStorage("FirstWeekday") private var firstWeekday = 0
    
    var body: some View{
        
        List {
            SwiftUI.Section {
                Picker("First day of week", selection: Binding(
                    get: { (0...2).contains(firstWeekday) ? firstWeekday : 0 },
                    set: { firstWeekday = $0 }
                )) {
                    Text("System Default").tag(0)
                    ForEach(1...2, id: \.self) { day in
                        Text(Calendar.autoupdatingCurrent.weekdaySymbols[day - 1]).tag(day)
                    }
                }
                .pickerStyle(.menu)
                .tint(.cPrimary)
                
                Picker("Day starts at", selection: $dayStartTime) {
                    ForEach(0..<24, id: \.self) { hour in
                        Text(hourLabel(hour)).tag(hour)
                    }
                }
                .pickerStyle(.menu)
                .tint(.cPrimary)
            }

        }
        .contentMargins(.bottom, 80, for: .scrollContent)
        .ignoresSafeArea(.container, edges: .bottom)
    }

    private func hourLabel(_ hour: Int) -> String {
        let date = Calendar.current.date(from: DateComponents(year: 2026, month: 1, day: 1, hour: hour)) ?? .now
        return date.formatted(date: .omitted, time: .shortened)
    }
}
