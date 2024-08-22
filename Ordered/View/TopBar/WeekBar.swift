//
//  WeekBar.swift
//  Ordered
//
//  Created by Kai Hin Hung on 28/7/2024.
//

import SwiftUI

struct WeekBar: View {
    @StateObject var viewModel: ContentViewModel
    @StateObject var dayPlannerVM: DayPlannerViewModel
    
    var body: some View{
        
        SwipeableStack(dayPlannerVM.startDateOfWeeksInAYear(), jumpTo: dayPlannerVM.startDateOfWeek(from: dayPlannerVM.currentDate)){ data, pos in
            Week(dayPlannerVM: dayPlannerVM, date: data, pos: pos)
        }
        .frame(height: 52)
    }
}

struct Week: View{
    @StateObject var dayPlannerVM: DayPlannerViewModel
    let date: Date //first day of week of all stacks
    let pos: ViewPosition
    let calendar = Calendar(identifier: .iso8601)
    
    var body: some View {
        let daysInAWeek = dayPlannerVM.datesInAWeek(from: date)
        HStack{
            ForEach(daysInAWeek.indices, id: \.self) { i in
                VStack{
                    Text(daysInAWeek[i].weekDayAbbrev())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, -5)
                    
                    
                    ZStack{
                        Circle()
                            .fill(calendar.isDate(daysInAWeek[i], inSameDayAs: dayPlannerVM.currentDate) ? .color3 : .color2)
                            .frame(width: K.large_size, height: K.large_size)
                        
                        Text(daysInAWeek[i].dayNum())
                            .foregroundStyle(Color(calendar.isDate(daysInAWeek[i], inSameDayAs: dayPlannerVM.currentDate) ? .white : .black))
                        
                    }
                    .onTapGesture {
                        dayPlannerVM.setCurrentDate(to: daysInAWeek[i])
                    }
                }
                if i != daysInAWeek.indices.last{
                    Spacer()
                }
            }
        }
        .onChange(of: date) {
            if pos == .centerView{
                let posInWeek = dayPlannerVM.currentPositionInWeek()
                let datesInAWeek = dayPlannerVM.datesInAWeek(from: date)
                dayPlannerVM.setCurrentDate(to: datesInAWeek[posInWeek])
            }
        }
    }
}

enum ViewPosition{
    case centerView
    case previousView
    case nextView
}


#Preview {
    WeekBar(viewModel: ContentViewModel(), dayPlannerVM: DayPlannerViewModel())
}
