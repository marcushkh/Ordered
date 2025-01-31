//
//  MainList.swift
//  Ordered
//
//  Created by Kai Hin Hung on 1/8/2024.
//

import SwiftUI

struct OneDay: View {
    
    var date: Date
    var pos: ViewPosition
    @ObservedObject var viewModel: ContentViewModel
    @ObservedObject var dayPlannerVM: DayPlannerViewModel
    
    @State var draggingItem: Event_Cal? = nil
    
    private var calendarFetchRequest: FetchRequest<Cal>
    
    init(date: Date, pos: ViewPosition, viewModel: ContentViewModel, dayPlannerVM: DayPlannerViewModel) {
        self.date = date
        
        self.calendarFetchRequest = FetchRequest(
            entity: Cal.entity(),
            sortDescriptors: [],
            predicate: NSPredicate(format: "date == %@", date.getYYMMDD())
        )
        
        self.pos = pos
        _viewModel = ObservedObject(wrappedValue: viewModel)
        _dayPlannerVM = ObservedObject(wrappedValue: dayPlannerVM)
        
    }
    
    var toDoForDate: FetchedResults<Cal> {
        calendarFetchRequest.wrappedValue
    }
    
    var body: some View {
        ScrollView{
            if toDoForDate.first != nil{
                
                ForEach(toDoForDate.first?.section_cals?.array as! [Section_Cal], id: \.self){ sc in
                    
                    VStack{
                        //Section Header
                        HStack(alignment: .bottom){
                            
                            Text(sc.name ?? "")
                                .font(.title3)
                                .bold()
                                .onTapGesture {
                                    viewModel.showChangeSection = true
                                    viewModel.changeSection_Cal = sc
                                    viewModel.insertToCal = nil
                                }
                            
                            Spacer()
                            
                            ColorPicker("", selection: Binding(get: {
                                Color(hex: sc.color)
                            }, set: { c in
                                let color: String = c.toHex() ?? "93e3fd"
                                sc.setColor(color)
                                viewModel.refresh.toggle()
                            }))
                            .labelsHidden()
                            .overlay{
                                Circle()
                                    .fill(Color(hex: sc.color))
                                    .frame(width: K.medium_size, height: K.medium_size)
                            }
                        }
                        
                        Divider()
                            .background(Color(.blue))
                            .frame(height: 2)
                            .padding(.top, -8)
                        
                        //Events
                        ForEach(sc.event_cals?.array as! [Event_Cal], id: \.self){ ec in
                            HStack{
                                ECInfo(ec: ec, refresh: viewModel.refresh)
                                
                                Spacer()
                                
                                if ec.duration == -1 && ec.startTime == nil {
                                    // Tick events
                                    ZStack{
                                        Circle()
                                            .fill(.color1)
                                            .frame(height: K.medium_size)
                                            .onChange(of: viewModel.refresh) { _, _ in
                                                print("viewModel.refreshed")
                                            }
                                        Image(systemName: "checkmark")
                                    }
                                }
                                else{
                                    ActionButtonView(viewModel: viewModel, ec: ec)
                                }
                            }
                            .background()
                            .onTapGesture {
                                viewModel.showEventDetail = true
                                viewModel.eventDetail = ec
                            }
                            
                            //For dragging capability
                            .draggable(ec.description){
                                ZStack{
                                    Circle()
                                        .fill(Color(hex: ec.section_cal?.color))
                                        .frame(height: K.xlarge_size)
                                    
                                    Text(ec.icon ?? "")
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
                                    if let draggingItem, status, draggingItem.objectID != ec.objectID{
                                        
                                        if let events = sc.event_cals?.mutableCopy() as? NSMutableOrderedSet {
                                            let e_index = events.index(of: ec)
                                            let d_index = events.index(of: draggingItem)
                                            
                                            if e_index != d_index { //Logic needed to add: start time need to be ordered
                                                events.remove(draggingItem)
                                                events.insert(draggingItem, at: e_index)
                                            }
                                            
                                            sc.event_cals = events.copy() as? NSOrderedSet
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
                        
                        //Create new Event
                        HStack{
                            ZStack{
                                Circle()
                                    .fill(Color(hex: sc.color))
                                    .frame(height: K.xlarge_size)
                                    .bold()
                                Image(systemName: "plus")
                            }
                            .padding(.trailing)
                            
                            Text("Add Event")
                                .bold()
                            
                            Spacer()
                        }
                        .background()
                        // On drop to put the event to the last part of the list
                        .dropDestination(for: String.self) { items, location in
                            draggingItem = nil
                            viewModel.refresh.toggle()
                            return false
                        } isTargeted: { status in
                            withAnimation {
                                if let draggingItem{
                                    if let events = sc.event_cals?.mutableCopy() as? NSMutableOrderedSet {
                                        let e_index = events.index(of: draggingItem)
                                        
                                        if e_index != events.count - 1{
                                            events.remove(draggingItem)
                                            events.add(draggingItem)
                                            sc.event_cals = events.copy() as? NSOrderedSet
                                        }
                                        
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
                        .onTapGesture {
                            viewModel.createEvent_Section_Cal = sc
                            viewModel.editEvent_Cal = nil
                            viewModel.showCreateEvent = true
                        }
                        
                    }
                    .padding(.top)
                    .padding(.horizontal, K.horizontal_padding)
                }
                //Create new Section
                HStack{
                    Rectangle()
                        .fill(Color(.color1))
                        .frame(height: 1)
                    
                    Image(systemName: "plus.circle")
                        .foregroundStyle(Color(.color1))
                    
                    Rectangle()
                        .fill(Color(.color1))
                        .frame(height: 1)
                }
                .padding(.top, 4)
                .background()
                .onTapGesture {
                    // Create new Section
                    viewModel.showChangeSection = true
                    viewModel.changeSection_Cal = nil
                    viewModel.insertToCal = toDoForDate.first
                }
                .padding(.bottom, 125)
                .padding(.horizontal, K.horizontal_padding)
            }
            else{
                //No event, show the image for event creation
                ZStack{
                    Rectangle()
                        .fill(.background)
                    VStack{
                        Image("NoEventIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 300)
                            .onTapGesture {
                                viewModel.editEvent_Cal = nil
                                viewModel.createEvent_Section_Cal = nil
                                viewModel.showCreateEvent = true
                            }
                        
                        Text("Decorate Your Schedule")
                            .font(.title2)
                            .bold()
                        
                        Spacer()
                    }
                    
                }
                
                
            }
        }
        .onChange(of: date) {
            if pos == .centerView{
                dayPlannerVM.setCurrentDate(to: date)
            }
        }
        .onChange(of: viewModel.refresh) { _, _ in
            print("viewModel.refreshed")
        }
    }
}

#Preview {
    OneDay(date: MyCalendar.getDate(from: "240826"), pos: .centerView, viewModel: ContentViewModel(), dayPlannerVM: DayPlannerViewModel())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
