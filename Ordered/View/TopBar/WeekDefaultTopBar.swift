//
//  WeekDefaultTopBar.swift
//  Ordered
//
//  Created by Kai Hin Hung on 20/2/2025.
//

import SwiftUI

struct WeekDefaultTopBar: View {
    let weekList = MyCalendar.getWeekOrder()
    
    var body: some View {
        HStack{
            ForEach(weekList, id: \.self) { i in
                VStack{
                    ZStack{
                        Circle()
                            .fill(.color2)
                            .frame(width: K.large_size, height: K.large_size)
                        
                        Text(Date.intToWeekAbbreviation(i) ?? "")
                            .font(.caption)
                            .foregroundStyle(.cPrimary)
                    }
                }
                if i != weekList.last{
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    WeekDefaultTopBar()
}
