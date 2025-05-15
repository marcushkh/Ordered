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
    
    @FetchRequest(
        sortDescriptors: [
            SortDescriptor(\.isFavourite, order: .reverse),
            SortDescriptor(\.order, order: .forward)
        ],
        predicate: NSPredicate(format: "isActive == true")
    )
    private var events: FetchedResults<Event>
    
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
    
    @State private var selection = "Event"
    let options = ["Location", "Event"]
    
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
                        ForEach(events) { e in
                            EventInfo(e: e)
                                .padding(.horizontal)
                                .onTapGesture {
                                    withAnimation {
                                        // Add event below the highlighted Event
                                        let newEC = e.getEC()
                                        
                                        if viewModel.currentTab == .plan /*&& viewModel.highlightedEC != nil*/{ //in planning page
                                            //if no Cal -> create Cal
                                            let cal = Cal.get(date: dayPlannerVM.currentDate.getYYMMDD()) ?? Cal.new(date: dayPlannerVM.currentDate.getYYMMDD())
                                            
                                            if let sc = viewModel.highlightedEC?.section_cal{
                                                sc.insert(newEC, after: viewModel.highlightedEC!)
                                            }
                                            else{
                                                let new_section_Cal = Section_Cal.new()
                                                
                                                new_section_Cal.add(event: newEC)
                                                cal.add(new_section_Cal)
                                            }
                                            cal.sort()
                                            viewModel.highlightedEC = newEC
                                            viewModel.highlightedSC = nil
                                        }
                                        
                                        viewModel.refresh.toggle()
                                    }
                                }
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
                                        if viewModel.currentTab == .plan {
                                            // Add location to the plan
                                            let cal = Cal.get(date: dayPlannerVM.currentDate.getYYMMDD()) ?? Cal.new(date: dayPlannerVM.currentDate.getYYMMDD())
                                            
                                            // Create a new section with this location
                                            let newSection = Section_Cal.new()
                                            newSection.location = location
                                            
                                            // If a section is highlighted, insert new section after it
                                            if let highlightedEC = viewModel.highlightedEC,
                                               let highlightedSection = highlightedEC.section_cal,
                                               let sections = cal.section_cals?.mutableCopy() as? NSMutableOrderedSet,
                                               sections.contains(highlightedSection) {
                                                
                                                let index = sections.index(of: highlightedSection)
                                                sections.insert(newSection, at: index + 1)
                                                cal.section_cals = sections
                                            } else {
                                                // No section highlighted, just add to cal
                                                cal.add(newSection)
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
            .onAppear{
                overlayHeight = UIScreen.main.bounds.height * 0.2
            }
            .frame(height: max(overlayHeight, 0))
            .background(.color2)
        }
        
    }
}
