//
//  WeekDefaultTopBar.swift
//  Ordered
//
//  Created by Kai Hin Hung on 20/2/2025.
//

import SwiftUI

struct WeekDefaultFunctionBar: View {
    @ObservedObject var viewModel: ContentViewModel
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        VStack{
            //two icon + theme of day
            HStack{
                Image(systemName: "calendar")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.color3)
                    .frame(height: K.xsmall_size)
                
                Spacer()
                
                Text("Weekly Default")
                    .font(.title2)
                    .bold()
                
                Spacer()
                
                Menu {
                    //TODO: Why does this not work in Real time?
                    if viewModel.highlightedEC != nil{
                        Button {
                            viewModel.highlightedEC?.toNewSection(colorScheme: colorScheme)
                            viewModel.refresh.toggle()
                        } label: {
                            Text("New Section")
                            Image(systemName: "folder")
                        }
                    }
                    
                } label: {
                    Image(systemName: "ellipsis")
                        .resizable()
                        .scaledToFit()
                        .frame(width: K.xsmall_size, height: K.xsmall_size)
                        .foregroundStyle(.color3)
                        .padding(.trailing, 4)
                }
            }
            .padding(.vertical)
        }
        .onChange(of: viewModel.refresh) { oldValue, newValue in
            
        }
    }
}


struct WeekDefaultTopBar: View {
    @ObservedObject var viewModel: ContentViewModel
    let weekList = MyCalendar.getWeekOrder()
    
    var body: some View {
        HStack{
            ForEach(weekList, id: \.self) { i in
                VStack{
                    ZStack{
                        var colorOfCircle: Color{
                            if viewModel.selectedWeekAb == i && viewModel.showWeekDetail == true {
                                return .color4
                            }
                            return .color2
                        }
                        Circle()
                            .fill(colorOfCircle)
                            .frame(width: K.large_size, height: K.large_size)
                        
                        Text(Date.intToWeekAbbreviation(i))
                            .font(.caption)
                            .foregroundStyle(.cPrimary)
                    }
                    .onTapGesture {
                        withAnimation {
                            viewModel.showEventBar = true
                            viewModel.selectedWeekAb = i
                            viewModel.showWeekDetail = true
                        }
                    }
                }
                if i != weekList.last{
                    Spacer()
                }
            }
        }
    }
}

