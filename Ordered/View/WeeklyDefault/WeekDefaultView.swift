//
//  week.swift
//  Ordered
//
//  Created by Kai Hin Hung on 18/2/2025.
//

import SwiftUI

struct WeekDefaultView: View {
    @ObservedObject var viewModel: ContentViewModel
    @State var draggingItem: Event_Cal? = nil
    let weekList = MyCalendar.getWeekOrder()
    
    var body: some View{
        ScrollViewReader{ proxy in
            ScrollView{
                HStack(alignment: .top){
                    ForEach(weekList, id: \.self) { i in
                        VStack{
                            let weekDefault = WeekDefault.get(i)
                            //For each
                            ForEach(weekDefault?.sections?.array as? [Section] ?? [], id: \.self){ s in
                                ForEach(s.event_cals?.array as? [Event_Cal] ?? [], id: \.self){ ec in
                                    ZStack{
                                        Circle()
                                            .fill(Color(hex: s.color))
                                            .frame(width: K.large_size, height: K.large_size)
                                            .overlay{
                                                if let highlightedEC = viewModel.highlightedEC, highlightedEC == ec {
                                                    if highlightedEC == ec{
                                                        Circle().stroke(Color.white, lineWidth: 4)
                                                    }
                                                }
                                            }
                                        
                                        Text(ec.parent?.icon ?? "")
                                            .font(.title2)
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
                                    
                                    .draggable(ec.description){
                                        ZStack{
                                            Circle()
                                                .fill(.clear)
                                                .frame(height: K.xlarge_size)
                                            
                                            Text(ec.parent?.icon ?? "")
                                                .font(.custom("", size: K.large_size))
                                                .shadow(radius: K.medium_size)
                                            
                                        }
                                        .onAppear {
                                            draggingItem = ec
                                        }
                                    }
                                    .dropDestination(for: String.self) { items, location in
                                        draggingItem = nil
                                        viewModel.refresh.toggle()
                                        return false
                                    } isTargeted: { status in
                                        withAnimation {
                                            //Reordering
                                            if let draggingItem, status, draggingItem.objectID != ec.objectID{
                                                
                                                //Logic needed to add: start time need to be ordered
                                                if let events = s.event_cals?.mutableCopy() as? NSMutableOrderedSet {
                                                    let e_index = events.index(of: ec)
                                                    
                                                    events.remove(draggingItem)
                                                    events.insert(draggingItem, at: e_index)
                                                    
                                                    s.event_cals = events.copy() as? NSOrderedSet
                                                    weekDefault?.sort()
                                                }
                                                
                                                do{
                                                    try PersistenceController.shared.container.viewContext.save()
                                                }
                                                catch{
                                                    fatalError("unresolved error \(error)")
                                                }
                                                viewModel.refresh.toggle()
                                            }
                                        }
                                    }
                                }
                            }
                            ZStack{
                                Circle()
                                    .fill(.color3)
                                    .frame(width: K.large_size, height: K.large_size)
                                    .overlay{
                                        if viewModel.selectedWeekAb == i && viewModel.highlightedEC == nil{
                                            Circle().stroke(.cPrimary, lineWidth: 4)
                                        }
                                    }
                                Image(systemName: "plus")
                            }
                            .id(i)
                            .onTapGesture {
                                withAnimation{
                                    if viewModel.showEventBar{
                                        viewModel.selectedWeekAb = i
                                        viewModel.showWeekDetail = true
                                        viewModel.refresh.toggle()
                                    }
                                    else{
                                        viewModel.highlightedEC = nil
                                        viewModel.selectedWeekAb = i
                                        viewModel.showEventBar = true
                                        viewModel.refresh.toggle()
                                    }
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
                .padding(.horizontal, K.horizontal_padding)
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
    }
}

#Preview{
    WeekDefaultView(viewModel: ContentViewModel())
}
