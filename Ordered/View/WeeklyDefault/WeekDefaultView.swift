//
//  week.swift
//  Ordered
//
//  Created by Kai Hin Hung on 18/2/2025.
//

import SwiftUI

struct WeekDefaultView: View {
    @ObservedObject var viewModel: ContentViewModel
    let weekList = MyCalendar.getWeekOrder()
    
    var body: some View{
        ScrollViewReader{ proxy in
            ScrollView{
                HStack(alignment: .top){
                    ForEach(weekList, id: \.self) { i in
                        VStack{
                            //For each
                            ForEach(WeekDefault.get(i)?.section_cals?.array as? [Section_Cal] ?? [], id: \.self){ sc in
                                ForEach(sc.event_cals?.array as? [Event_Cal] ?? [], id: \.self){ ec in
                                    ZStack{
                                        Circle()
                                            .fill(Color(hex: sc.color))
                                            .frame(width: K.large_size, height: K.large_size)
                                            .overlay{
                                                if let highlightedEC = viewModel.highlightedEC, highlightedEC == ec {
                                                    if highlightedEC == ec{
                                                        Circle().stroke(Color.white, lineWidth: 2)
                                                    }
                                                }
                                            }
                                        
                                        Text(ec.parent?.icon ?? "")
                                    }
                                    .id(ec.id)
                                    .onTapGesture {
                                        withAnimation {
                                            viewModel.highlightedEC = ec
                                            viewModel.selectedWeekAb = i
                                            viewModel.showEventBar = true
                                            viewModel.refresh.toggle()
                                        }
                                    }
                                }
                            }
                            ZStack{
                                Circle()
                                    .fill(.color3)
                                    .frame(width: K.large_size, height: K.large_size)
                                    .overlay{
                                        if viewModel.selectedWeekAb == i{
                                            Circle().stroke(.cPrimary, lineWidth: 2)
                                        }
                                    }
                                Image(systemName: "plus")
                            }
                            .id(i)
                            .onTapGesture {
                                withAnimation{
                                    viewModel.highlightedEC = nil
                                    viewModel.selectedWeekAb = i
                                    viewModel.showEventBar = true
                                    viewModel.refresh.toggle()
                                }
                            }
                            
                        }
                        if i != weekList.last{
                            Spacer()
                        }
                    }
                }
                .padding(.vertical)
                .padding(.bottom, 24)
                .onChange(of: viewModel.refresh) { _, _ in
                    
                }
            }
            .onChange(of: viewModel.highlightedEC) { _, _ in
                withAnimation {
                    if let ec = viewModel.highlightedEC{
                        proxy.scrollTo(ec.id, anchor: .center)
                    }
                    else if let weekAb = viewModel.selectedWeekAb{
                        proxy.scrollTo(weekAb, anchor: .center)
                    }
                }
            }
        }
        .padding(.vertical)
    }
}

#Preview{
    WeekDefaultView(viewModel: ContentViewModel())
}
