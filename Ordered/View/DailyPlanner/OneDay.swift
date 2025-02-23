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
    @State var showAlert: Bool = false
    
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
        ScrollViewReader{ proxy in
            ScrollView{
                if toDoForDate.first != nil && toDoForDate.first?.section_cals?.count != 0{
                    
                    ForEach(toDoForDate.first?.section_cals?.array as! [Section_Cal], id: \.self){ sc in
                        
                        VStack{
                            //Section Header
                            HStack(alignment: .center){
                                
                                Text(sc.name ?? "")
                                    .font(.title3)
                                    .bold()
                                
                                Spacer()
                                
                                Menu {
                                    Button {
                                        createSection(above: sc)
                                    } label: {
                                        Text("Add Section Above")
                                        Image(systemName: "arrow.up")
                                    }
                                    
                                    Button {
                                        createSection(below: sc)
                                    } label: {
                                        Text("Add Section Below")
                                        Image(systemName: "arrow.down")
                                    }
                                    
                                    Button {
                                        edit(sc: sc)
                                    } label: {
                                        Text("Edit Section")
                                        Image(systemName: "pencil.line")
                                    }
                                    
                                    Button(role: .destructive) {
                                        showAlert = true
                                    } label: {
                                        Text("Delete Section")
                                            .foregroundColor(.red)
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                } label: {
                                    ZStack{
                                        Image(systemName: "ellipsis.circle.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .foregroundStyle(.cPrimary, .cBackground)
                                            .frame(width: K.medium_size)
                                    }
                                    .background()
                                }
                                .alert(isPresented: $showAlert) {
                                    Alert(  title: Text("Delete Section"),
                                            message: Text("Are you sure you want to delete this Section?"),
                                            primaryButton: .destructive(Text("Delete")) {
                                                sc.delete()
                                            },
                                            secondaryButton: .cancel())
                                }
                            }
                            .onTapGesture {
                                edit(sc: sc)
                            }
                            .id(sc.id)
                            
                            Divider()
                                .background(Color(.blue))
                                .frame(height: 2)
                                .padding(.top, -8)
                            
                            //Events
                            ForEach(sc.event_cals?.array as! [Event_Cal], id: \.self){ ec in
                                HStack{
                                    ECInfo(ec: ec, refresh: viewModel.refresh, highlightedEC: $viewModel.highlightedEC)
                                    
                                    Spacer()
                                    
                                    //Schedule events or Duration events
                                    if viewModel.currentTab == .home{
                                        ActionButtonView(viewModel: viewModel, sc: sc, ec: ec)
                                    }
                                    else if viewModel.currentTab == .plan{
                                        EditDeleteButtonView(viewModel: viewModel, sc: sc, ec: ec)
                                    }
                                }
                                .background()
                                .onTapGesture {
                                    withAnimation {
                                        if viewModel.currentTab == .plan{
                                            viewModel.highlightedEC = ec
                                        }
                                        else{
                                            viewModel.showEventDetail = true
                                            viewModel.eventDetail = ec
                                        }
                                    }
                                }
                                .id(ec.id)
                                
                                //For dragging capability
                                .draggable(ec.description){
                                    ZStack{
                                        Circle()
                                            .fill(Color(hex: ec.section_cal?.color))
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
                                            if let events = sc.event_cals?.mutableCopy() as? NSMutableOrderedSet {
                                                let e_index = events.index(of: ec)
                                                
                                                events.remove(draggingItem)
                                                events.insert(draggingItem, at: e_index)
                                                
                                                sc.event_cals = events.copy() as? NSOrderedSet
                                                toDoForDate.first?.sort()
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
                                                toDoForDate.first?.sort()
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
                                //Create event
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
                        createSection()
                    }
                    //Padding at the bottom to allow Users to scroll down, for planning page needs more
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
                //sort everytime something refreshes
                withAnimation {
                    toDoForDate.first?.sort()
                }
            }
            // For HighlighedEC
            .onChange(of: viewModel.currentTab) { _, _ in
                if viewModel.currentTab == .plan && pos == .centerView{
                    withAnimation {
                        viewModel.highlightedEC = toDoForDate.first?.getLastFinishedEvent()
                    }
                }
            }
            .onChange(of: date) {
                //Change highlightedEC
                if viewModel.currentTab == .plan && pos == .centerView{
                    withAnimation {
                        viewModel.highlightedEC = toDoForDate.first?.getLastFinishedEvent()
                    }
                }
            }
            .onChange(of: viewModel.highlightedEC) { _, _ in
                withAnimation {
                    if pos == .centerView{
                        proxy.scrollTo(viewModel.highlightedEC?.id, anchor: .top)
                    }
                }
            }
        }
    }
    
    func edit(sc: Section_Cal){
        viewModel.showChangeSection = true
        viewModel.changeSection_Cal = sc
        viewModel.changeSection = nil
        viewModel.insertToCal = toDoForDate.first
    }
    func createSection(above: Section_Cal? = nil, below: Section_Cal? = nil){
        if let sc = above{
            viewModel.insertIndex = toDoForDate.first?.section_cals?.index(of: sc)
        }
        else if let sc = below{
            viewModel.insertIndex = (toDoForDate.first?.section_cals?.index(of: sc) ?? 0) + 1
        }
        //Put it at the very end
        viewModel.showChangeSection = true
        viewModel.changeSection_Cal = nil
        viewModel.changeSection = nil
        viewModel.insertToCal = toDoForDate.first
    }
}

#Preview {
    OneDay(date: MyCalendar.getDate(from: "240826"), pos: .centerView, viewModel: ContentViewModel(), dayPlannerVM: DayPlannerViewModel())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
