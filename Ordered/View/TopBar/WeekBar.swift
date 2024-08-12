//
//  WeekBar.swift
//  Ordered
//
//  Created by Kai Hin Hung on 28/7/2024.
//

import SwiftUI

struct WeekBar: View {
    @StateObject var viewModel = DayPlannerViewModel()
    
    var body: some View{
        let mondayOfTheCurrentDate = viewModel.startDateOfWeek(from: viewModel.currentDate)
        SwipeableStack(viewModel.startDateOfWeeksInAYear(), jumpTo: mondayOfTheCurrentDate){ data in
            Week(dayPlannerVM: viewModel, date: data)
        }
    }
}

struct SwipeableStack<WhateverTypeOfData: Hashable, Content>: View where Content : View{
    var WhateverData: [WhateverTypeOfData] = []
    let content: (WhateverTypeOfData) -> Content
    var jumpTo: WhateverTypeOfData?
    
    @State private var dragged = CGSize.zero
    @State var dataIndex = 1
    
    var previousExist: Bool{
        return (dataIndex - 1) >= 0
    }
    var nextExist: Bool{
        return dataIndex < (WhateverData.count - 1)
    }
    
    init(_ data: [WhateverTypeOfData], jumpTo: WhateverTypeOfData? = nil, @ViewBuilder content: @escaping (WhateverTypeOfData) -> Content) {
        self.WhateverData = data
        self.content = content
        if let jumpTo{
            self.jumpTo = jumpTo
        }
    }
    
    var body: some View{
        GeometryReader{ geo in
            let w = geo.size.width
            HStack(spacing: K.horizontal_padding * 2){
                if previousExist{
                    content(WhateverData[dataIndex - 1]) //Last week
                        .frame(width: w)
                        .offset(x: previousExist ? -w-K.horizontal_padding*2 : 0)
                }
                content(WhateverData[dataIndex]) //This week
                    .frame(width: w)
                        .offset(x: previousExist ? -w-K.horizontal_padding*2 : 0)
                if nextExist{
                    content(WhateverData[dataIndex + 1]) //Next week
                        .frame(width: w)
                        .offset(x: previousExist ? -w-K.horizontal_padding*2 : 0)
                }
            }
            .onAppear {
                if let jumpTo{
                    if let pos = WhateverData.firstIndex(of: jumpTo) {
                        dataIndex = pos
                    }
                }
            }
            .offset(x: dragged.width)
            .gesture(
                DragGesture()
                    .onChanged({ value in
                        dragged.width = value.translation.width
                    })
                    .onEnded({ value in
                        var indexOffset = 0
                        withAnimation(.smooth(duration: 0.5)) {
                            dragged = CGSize.zero
                            if value.predictedEndTranslation.width < -w/2 && nextExist{
                                dragged.width = -w - K.horizontal_padding*2
                                indexOffset = 1 //Next
                            }
                            if value.predictedEndTranslation.width > w/2 && previousExist{
                                dragged.width = w + K.horizontal_padding*2
                                indexOffset = -1 //Previous
                            }
                            
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                            dragged = CGSize.zero
                            if indexOffset == 1 && nextExist{
                                dataIndex += indexOffset
                            }
                            if indexOffset == -1 && previousExist{
                                dataIndex += indexOffset
                            }
                        }
                    })
            )
        }
        .frame(height: 52)
    }
}

struct Week: View{
    @StateObject var dayPlannerVM: DayPlannerViewModel
    let date: Date //first day of week
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
                }
                if i != daysInAWeek.indices.last{
                    Spacer()
                }
            }
        }
        
    }
}


#Preview {
    WeekBar()
}
