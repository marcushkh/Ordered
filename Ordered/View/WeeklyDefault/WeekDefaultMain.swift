//
//  WeekDefaultMain.swift
//  Ordered
//
//  Created by Kai Hin Hung on 21/2/2025.
//
import SwiftUI

struct WeekDefaultMainList: View{
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View {
        GeometryReader{geo in
            SwipeableStack(MyCalendar.getWeekOrder(), jumpTo: viewModel.selectedWeekAb) { weekAb, pos in
                WeekDefaultMain(weekAb: weekAb, pos: pos, viewModel: viewModel)
            }
            .onChange(of: viewModel.selectedWeekAb, { oldValue, newValue in
                
            })
            .frame(height: geo.size.height)
        }
    }
}

struct WeekDefaultMain: View {
    var weekAb: Int
    var pos: ViewPosition
    @ObservedObject var viewModel: ContentViewModel
    @State var draggingItem: Event_Cal? = nil
    
    private var weekDefaultFetchRequest: FetchRequest<WeekDefault>
    @State var showAlert: Bool = false
    
    init(weekAb: Int, pos: ViewPosition, viewModel: ContentViewModel) {
        self.weekAb = weekAb
        self.weekDefaultFetchRequest = FetchRequest(
            entity: WeekDefault.entity(),
            sortDescriptors: [],
            predicate: NSPredicate(format: "weekAb == %d", weekAb)
        )
        
        self.pos = pos
        _viewModel = ObservedObject(wrappedValue: viewModel)
        
    }
    
    var weekDefault: FetchedResults<WeekDefault> {
        weekDefaultFetchRequest.wrappedValue
    }
    
    var body: some View {
        ScrollViewReader{ proxy in
            ScrollView{
                if weekDefault.first != nil && weekDefault.first?.sections?.count != 0{
                    
                    ForEach(weekDefault.first?.sections?.array as! [Section], id: \.self){ s in
                        
                        VStack{
                            //Section Header
                            HStack(alignment: .center){
                                
                                Text(s.name ?? "")
                                    .font(.title3)
                                    .bold()
                                
                                Spacer()
                                
                                Menu {
                                    Button {
                                        createSection(above: s)
                                    } label: {
                                        Text("Add Section Above")
                                        Image(systemName: "arrow.up")
                                    }
                                    
                                    Button {
                                        createSection(below: s)
                                    } label: {
                                        Text("Add Section Below")
                                        Image(systemName: "arrow.down")
                                    }
                                    
                                    Button {
                                        edit(s: s)
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
                                                s.delete()
                                            },
                                            secondaryButton: .cancel())
                                }
                            }
                            .onTapGesture {
                                edit(s: s)
                            }
                            .id(s.id)
                            
                            Divider()
                                .background(Color(.blue))
                                .frame(height: 2)
                                .padding(.top, -8)
                            
                            //Events
                            ForEach(s.event_cals?.array as! [Event_Cal], id: \.self){ ec in
                                HStack{
                                    ECInfo(ec: ec, refresh: viewModel.refresh, highlightedEC: $viewModel.highlightedEC)
                                    
                                    Spacer()
                                    
                                    //Schedule events or Duration events
//                                    if viewModel.currentTab == .home{
//                                        ActionButtonView(viewModel: viewModel, sc: s, ec: ec)
//                                    }
//                                    else if viewModel.currentTab == .plan{
//                                        EditDeleteButtonView(viewModel: viewModel, sc: sc, ec: ec)
//                                    }
                                }
                                .background()
                                .onTapGesture {
                                    withAnimation {
                                        if viewModel.currentTab == .plan || viewModel.currentTab == .weeklyDefault{
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
                                            if let events = s.event_cals?.mutableCopy() as? NSMutableOrderedSet {
                                                let e_index = events.index(of: ec)
                                                
                                                events.remove(draggingItem)
                                                events.insert(draggingItem, at: e_index)
                                                
                                                s.event_cals = events.copy() as? NSOrderedSet
                                                weekDefault.first?.sort()
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
                                        .fill(Color(hex: s.color))
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
                                        if let events = s.event_cals?.mutableCopy() as? NSMutableOrderedSet {
                                            let e_index = events.index(of: draggingItem)
                                            
                                            if e_index != events.count - 1{
                                                events.remove(draggingItem)
                                                events.add(draggingItem)
                                                
                                                s.event_cals = events.copy() as? NSOrderedSet
                                                weekDefault.first?.sort()
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
                                viewModel.createEvent_Section = s
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
                                    viewModel.createEvent_Section = nil
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
            .onChange(of: weekAb) {
                if pos == .centerView{
                    viewModel.selectedWeekAb = weekAb
                }
            }
            .onChange(of: viewModel.refresh) { _, _ in
                //sort everytime something refreshes
                withAnimation {
                    weekDefault.first?.sort()
                }
            }
            // For HighlighedEC
            .onChange(of: viewModel.showWeekDetail) { _, _ in
                if viewModel.showWeekDetail == true && pos == .centerView{
                    withAnimation {
                        viewModel.highlightedEC = weekDefault.first?.getLastFinishedEvent()
                    }
                }
            }
            .onChange(of: weekAb) {
                //Change highlightedEC
                if viewModel.currentTab == .weeklyDefault && pos == .centerView{
                    withAnimation {
                        viewModel.highlightedEC = weekDefault.first?.getLastFinishedEvent()
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
    
    //TODO: TO do this change this to Section Type
    func edit(s: Section){
        viewModel.showChangeSection = true
        viewModel.changeSection_Cal = nil
        viewModel.changeSection = s
        viewModel.insertToWeek = weekDefault.first
    }
    func createSection(above: Section? = nil, below: Section? = nil){
        if let s = above{
            viewModel.insertIndex = weekDefault.first?.sections?.index(of: s)
        }
        else if let s = below{
            viewModel.insertIndex = (weekDefault.first?.sections?.index(of: s) ?? 0) + 1
        }
        //Put it at the very end
        viewModel.showChangeSection = true
        viewModel.changeSection_Cal = nil
        viewModel.changeSection = nil
        viewModel.insertToWeek = weekDefault.first
    }
}

