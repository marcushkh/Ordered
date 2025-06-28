//
//  EventBar.swift
//  Ordered
//
//  Created by Kai Hin Hung on 5/8/2024.
//

import SwiftUI

struct EventBar: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    
    @ObservedObject var viewModel: ContentViewModel
    @ObservedObject var dayPlannerVM: DayPlannerViewModel
    
    @FetchRequest private var events: FetchedResults<Event>
    
    @FetchRequest(
        sortDescriptors: [
            SortDescriptor(\.positionOrder, order: .forward)
        ]
    )
    private var locations: FetchedResults<Location>
    
    @State var overlayHeight: CGFloat = UIScreen.main.bounds.height * 0.2
    @State var lastHeight: CGFloat = UIScreen.main.bounds.height * 0.2
    @GestureState private var dragOffset: CGFloat = 0
    
    let dismissHeight: CGFloat = 0
    let minHeight: CGFloat = UIScreen.main.bounds.height * 0.2
    let midHeight: CGFloat = UIScreen.main.bounds.height * 0.5
    
    @State private var selection = "Location"
    let options = ["Location", "Event"]
    
    init(viewModel: ContentViewModel, dayPlannerVM: DayPlannerViewModel) {
        self.viewModel = viewModel
        self.dayPlannerVM = dayPlannerVM
        
        let predicate: NSPredicate
        if let location = viewModel.highlightedEC?.section_cal?.location {
            predicate = NSPredicate(format: "isActive == true AND ANY locations == %@", location)
        } else if let location = viewModel.highlightedSC?.location {
            predicate = NSPredicate(format: "isActive == true AND ANY locations == %@", location)
        } else {
            predicate = NSPredicate(format: "isActive == true")
        }
        
        _events = FetchRequest(
            sortDescriptors: [
                SortDescriptor(\.isFavourite, order: .reverse),
                SortDescriptor(\.order, order: .forward)
            ],
            predicate: predicate
        )
    }
    
    var body: some View {
        VStack(spacing: 0){
            
            VStack{
                // Drag Handle
                HStack {
                    Spacer()
                    Capsule()
                        .fill(Color.color3.opacity(0.5))
                        .frame(width: 90, height: 5)
                    Spacer()
                }
            }
            .padding(.top)
            .padding(.horizontal, K.horizontal_padding)
            .background(.color2)
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30))
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .global)
                    .onChanged { value in
                        // Remove withAnimation to prevent flickering during drag
                        withAnimation{
                            overlayHeight = lastHeight - value.translation.height
                        }
                    }
                    .onEnded { value in
                        let newHeight = lastHeight - value.translation.height
                        
                        if abs(newHeight - dismissHeight) < abs(newHeight - minHeight) {// Closer to dismiss Height
                            withAnimation {
                                if viewModel.currentTab == .plan{
                                    viewModel.currentTab = .home
                                }
                                viewModel.highlightedEC = nil
                                viewModel.highlightedSC = nil
                            }
                        }
                        
                        // Snap to closest height
                        let closestHeight = [minHeight, midHeight]
                            .min(by: { abs($0 - newHeight) < abs($1 - newHeight) }) ?? minHeight
                        
                        withAnimation{
                            overlayHeight = closestHeight
                            lastHeight = closestHeight
                        }
                    }
            )
            
            HStack{
                Picker("", selection: $selection) {
                    ForEach(options, id: \.self) { option in
                        Text(option)
                    }
                }
                .pickerStyle(.segmented)
                .showCase(order: 3, title: "Select Location or Event", cornerRadius: 20){
                    selection = "Event"
                }
            }
            .padding(.vertical)
            .padding(.horizontal, K.horizontal_padding)
            .background(.color2)
            
            //Events
            ScrollView{
                
                if selection == "Event"{
                    LazyVGrid(
                        columns: [GridItem(), GridItem()],
                        spacing: K.horizontal_padding,
                        content: {
                        ForEach(Array(events.enumerated()), id: \.element.id) { index, e in
                            EventInfo(e: e)
                                .padding(.horizontal)
                                .modifier(
                                    EventTapModifier(
                                        event: e,
                                        index: index,
                                        viewModel: viewModel,
                                        dayPlannerVM: dayPlannerVM
                                    )
                                )
                        }
                    })
                    .padding(.bottom, 0)
                }
                
                else if selection == "Location" {
                    LazyVGrid(columns: [GridItem(), GridItem()],spacing: K.horizontal_padding, content: {
                        ForEach(locations) { location in
                            LocationInfo(location: location)
                                .padding(.horizontal)
                                .onTapGesture {
                                    withAnimation {
                                        HapticFeedback.light()
                                        if viewModel.currentTab == .plan {
                                            // Add location to the plan
                                            let cal = Cal.get(date: dayPlannerVM.currentDate.getYYMMDD()) ?? Cal.new(date: dayPlannerVM.currentDate.getYYMMDD())
                                            
                                            // Create a new section with this location
                                            let newSection = Section_Cal.new()
                                            newSection.location = location
                                            
                                            // If a highlighted EC exists, insert the section after its parent section
                                            if let highlightedEC = viewModel.highlightedEC,
                                               let highlightedSection = highlightedEC.section_cal,
                                               let sections = cal.section_cals?.mutableCopy() as? NSMutableOrderedSet,
                                               sections.contains(highlightedSection) {
                                                
                                                let index = sections.index(of: highlightedSection)
                                                sections.insert(newSection, at: index + 1)
                                                cal.section_cals = sections
                                                viewModel.highlightedSC = newSection
                                                viewModel.highlightedEC = nil
                                            } 
                                            // If a highlighted SC exists, insert the new section after it
                                            else if let highlightedSC = viewModel.highlightedSC,
                                                    let sections = cal.section_cals?.mutableCopy() as? NSMutableOrderedSet,
                                                    sections.contains(highlightedSC) {
                                                
                                                let index = sections.index(of: highlightedSC)
                                                sections.insert(newSection, at: index + 1)
                                                cal.section_cals = sections
                                                viewModel.highlightedSC = newSection
                                                viewModel.highlightedEC = nil
                                            }
                                            // If neither is highlighted, add the section to the end
                                            else {
                                                cal.add(newSection)
                                                viewModel.highlightedSC = newSection
                                                viewModel.highlightedEC = nil
                                            }
                                            
                                            cal.sort()
                                            viewModel.refresh.toggle()
                                        }
                                    }
                                }
                        }
                    })
                    .padding(.bottom, 0)
                }
            }
            .scrollIndicators(.hidden)
            .onAppear{
                overlayHeight = UIScreen.main.bounds.height * 0.2
            }
            .frame(height: max(overlayHeight, 0))
            .background(.color2)
        }
        .onChange(of: viewModel.highlightedEC) { _, _ in
            updatePredicate()
        }
        .onChange(of: viewModel.highlightedSC) { _, _ in
            updatePredicate()
        }
    }
    
    // Add method to update the predicate
    private func updatePredicate() {
        let predicate: NSPredicate
        if let location = viewModel.highlightedEC?.section_cal?.location {
            predicate = NSPredicate(format: "isActive == true AND ANY locations == %@", location)
        } else if let location = viewModel.highlightedSC?.location {
            predicate = NSPredicate(format: "isActive == true AND ANY locations == %@", location)
        } else {
            predicate = NSPredicate(format: "isActive == true")
        }
        
        events.nsPredicate = predicate
    }
}

struct EventTapModifier: ViewModifier {
    let event: Event
    let index: Int
    @ObservedObject var viewModel: ContentViewModel
    @ObservedObject var dayPlannerVM: DayPlannerViewModel
    
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                handleEventTap()
            }
            .modifier(ShowcaseModifier(viewModel: viewModel, index: index){
                handleEventTap()
            })
    }
    
    private func handleEventTap() {
        withAnimation {
            HapticFeedback.light()
            // Add event below the highlighted Event
            let newEC = event.getEC()
            
            if viewModel.currentTab == .plan { //in planning page
                //if no Cal -> create Cal
                let cal = Cal.get(date: dayPlannerVM.currentDate.getYYMMDD()) ?? Cal.new(date: dayPlannerVM.currentDate.getYYMMDD())
                
                // If highlightedEC is not nil, create new event_cal and put it below highlightedEC
                if let highlightedEC = viewModel.highlightedEC, 
                   let sc = highlightedEC.section_cal {
                    sc.insert(newEC, after: highlightedEC)
                    viewModel.highlightedEC = newEC
                    viewModel.highlightedSC = nil
                }
                // If highlightedSC is not nil, put the new event_cal under the highlighed SC
                else if let highlightedSC = viewModel.highlightedSC {
                    highlightedSC.add(event: newEC)
                    viewModel.highlightedEC = newEC
                    viewModel.highlightedSC = nil
                }
                // If both highlighted EC and SC are nil, create a new section
                else {
                    let new_section_Cal = Section_Cal.new()
                    new_section_Cal.add(event: newEC)
                    cal.add(new_section_Cal)
                    viewModel.highlightedEC = newEC
                    viewModel.highlightedSC = nil
                }
                
                cal.sort()
            }
            
            viewModel.refresh.toggle()
        }
    }
}

struct ShowcaseModifier: ViewModifier {
    @ObservedObject var viewModel: ContentViewModel
    
    let index: Int
    let onCompletion: (() -> Void)?
    
    func body(content: Content) -> some View {
        Group {
            if index == 0 {
                content
                    .showCase(order: 4, title: "One Tap = Create One Events", cornerRadius: 10) {
                        if let C = onCompletion{
                            withAnimation {
                                C()
                                if Event.count() == 1 {
                                    viewModel.currentTab = .home
                                }
                            }
                        }
                    }
            }
            else if index == 1 {
                content
                    .showCase(order: 5, title: "Continue Creating Events!!", cornerRadius: 10) {
                        if let C = onCompletion{
                            withAnimation {
                                C()
                                viewModel.currentTab = .home
                            }
                        }
                    }
            }
            else {
                content
            }
        }
    }
}
