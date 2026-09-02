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
    @State var activeAlert: ActiveAlert?

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
        VStack{

            ScrollViewReader{ proxy in
                ScrollView{
                    // Check if we have a Cal for this date
                    let currentCal = toDoForDate.first ?? Cal.getOrCreateWithDefault(date: date)

                    // Always show the calendar content since we now ensure there's always at least a Wake Up event
                    ForEach(currentCal.section_cals?.array as! [Section_Cal], id: \.self){ sc in

                        VStack{
                            //Section Header
                            HStack(alignment: .center){

                                HStack(alignment: .center){
                                    if let section = sc.parent {
                                        Text(section.icon ?? "📁")
                                            .font(.title2)

                                        Text(section.name ?? "Section")
                                            .font(.title3)
                                            .bold()
                                    }
                                    else{
                                        Image(systemName: "rectangle.stack")
                                            .font(.title3)

                                        Text("Select Section")
                                            .font(.title3)
                                            .bold()
                                    }
                                    if sc == viewModel.highlightedSC{
                                        Image(systemName: "star.circle")
                                            .bold()

                                    }
                                }
                                .foregroundStyle(sc == viewModel.highlightedSC ? .color3 : .cPrimary)

                                Spacer()

                                Menu {
                                    Button {
                                        let newSC = toDoForDate.first?.addSection(above: sc)

                                        // Set this as highlighted in plan mode
                                        if viewModel.currentTab == .plan {
                                            viewModel.highlightedEC = nil
                                            viewModel.highlightedSC = newSC
                                        }
                                        viewModel.refresh.toggle()
                                    } label: {
                                        Text("Add Section Above")
                                        Image(systemName: "arrow.up")
                                    }

                                    Button {
                                        let newSC = toDoForDate.first?.addSection(below: sc)
                                        // Set this as highlighted in plan mode
                                        if viewModel.currentTab == .plan {
                                            viewModel.highlightedEC = nil
                                            viewModel.highlightedSC = newSC
                                        }
                                        viewModel.refresh.toggle()
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
                                        activeAlert = .deleteSectionCal(sc)
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

                            }
                            .onTapGesture {
                                HapticFeedback.light()
                                if viewModel.currentTab == .plan{
                                    viewModel.highlightedEC = nil
                                    viewModel.highlightedSC = sc
                                }
                                else{
                                    edit(sc: sc)
                                }
                            }
                            .id(sc.id)

                            Divider()
                                .background(Color(.color3))
                                .frame(height: 2)
                                .padding(.top, -8)

                            //Events
                            ForEach(sc.event_cals?.array as! [Event_Cal], id: \.self){ ec in
                                HStack{
                                    ECInfo(ec: ec, refresh: viewModel.refresh, highlightedEC: $viewModel.highlightedEC)

                                    Spacer()

                                    // Tick action
                                    if viewModel.currentTab == .home{
                                        ActionButtonView(viewModel: viewModel, sc: sc, ec: ec)
                                    }
                                    else if viewModel.currentTab == .plan{
                                        EditDeleteButtonView(viewModel: viewModel, ec: ec, activeAlert: $activeAlert)
                                    }
                                }
                                .background()
                                .onTapGesture {
                                    withAnimation {
                                        if viewModel.currentTab == .plan{
                                            viewModel.highlightedEC = ec
                                            viewModel.highlightedSC = nil
                                        }
                                        else{
                                            // Check if event_cal has no parent (empty event from stationary detection)
                                            if ec.parent == nil {
                                                viewModel.emptyEventCal = ec
                                                viewModel.eventSelectionSectionCal = ec.section_cal
                                                viewModel.showEmptyEventSelection = true
                                            } else {
                                                viewModel.showEventDetail = true
                                                viewModel.eventDetail = ec
                                            }
                                        }
                                    }
                                }
                                .id(ec.id)

                                //For dragging capability
                                .draggable(ec.description){
                                    ZStack{
                                        Circle()
                                            .fill(Color(hex: ec.section_cal?.parent?.color))
                                            .frame(height: K.xlarge_size)

                                        Text(ec.parent?.icon ?? "")
                                            .font(.custom("", size: K.large_size))
                                            .shadow(radius: K.medium_size)

                                    }
                                    .onAppear {
                                        HapticFeedback.light()
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

                                                events.remove(draggingItem)
                                                events.insert(draggingItem, at: e_index)

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
                                        .fill(Color(hex: sc.parent?.color))
                                        .frame(height: K.xlarge_size)
                                        .bold()
                                    Image(systemName: "plus")
                                }
                                .padding(.trailing)

                                Text("Add Event")
                                    .bold()

                                Spacer()
                            }
                            .conditionalShowCase(isShow: pos == .centerView, order: 1, title: "Create New Events", cornerRadius: 10)
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
                                HapticFeedback.light()
                                withAnimation {
                                    // Open the picker directly. The Event_Cal is only
                                    // inserted after the user chooses an event, so no
                                    // intermediate "Select Event" row is displayed.
                                    viewModel.emptyEventCal = nil
                                    viewModel.eventSelectionSectionCal = sc
                                    viewModel.showEmptyEventSelection = true
                                }
                            }

                        }
                        .padding(.top)
                        .padding(.horizontal, K.horizontal_padding)
                    }
                    .alert(item: $activeAlert) { alert in
                        switch alert {
                        case .deleteSectionCal(let sc):
                            return Alert(
                                title: Text("Delete Section"),
                                message: Text("Are you sure you want to delete this Section?"),
                                primaryButton: .destructive(Text("Delete")) {
                                    withAnimation {
                                        if viewModel.highlightedSC == sc {
                                            let cal = toDoForDate.first
                                            let sections = cal?.section_cals?.array as? [Section_Cal] ?? []
                                            if let index = sections.firstIndex(of: sc) {
                                                // Try to find a section above
                                                if index > 0 {
                                                    let sectionAbove = sections[index - 1]
                                                    let eventsInSectionAbove = sectionAbove.event_cals?.array as? [Event_Cal] ?? []

                                                    if !eventsInSectionAbove.isEmpty {
                                                        // Make the last event of the section above the highlightedEC
                                                        viewModel.highlightedEC = eventsInSectionAbove.last
                                                        viewModel.highlightedSC = nil
                                                    } else {
                                                        // Make the section above the highlightedSC
                                                        viewModel.highlightedSC = sectionAbove
                                                        viewModel.highlightedEC = nil
                                                    }
                                                }
                                                // If no section above, try to find a section below
                                                else if index + 1 < sections.count {
                                                    let sectionBelow = sections[index + 1]
                                                    let eventsInSectionBelow = sectionBelow.event_cals?.array as? [Event_Cal] ?? []

                                                    if !eventsInSectionBelow.isEmpty {
                                                        // Make the first event of the section below the highlightedEC
                                                        viewModel.highlightedEC = eventsInSectionBelow.first
                                                        viewModel.highlightedSC = nil
                                                    } else {
                                                        // Make the section below the highlightedSC
                                                        viewModel.highlightedSC = sectionBelow
                                                        viewModel.highlightedEC = nil
                                                    }
                                                } else {
                                                    // No sections above or below
                                                    viewModel.highlightedEC = nil
                                                    viewModel.highlightedSC = nil
                                                }
                                            }
                                        }

                                        sc.delete()
                                    }
                                },
                                secondaryButton: .cancel()
                            )
                        case .deleteEvent(let ec_del):
                            return Alert(
                                title: Text("Delete Event"),
                                message: Text("Are you sure you want to delete this event?"),
                                primaryButton: .destructive(Text("Delete")) {
                                    withAnimation {
                                        if viewModel.highlightedEC == ec_del{
                                            var i: Int?{
                                                return ec_del.section_cal?.event_cals?.index(of: ec_del)
                                            }
                                            var size: Int?{
                                                return ec_del.section_cal?.event_cals?.count
                                            }

                                            let currentSC = ec_del.section_cal

                                            if let i = i, let size = size{
                                                if i > 0 {
                                                    viewModel.highlightedEC = ec_del.section_cal?.event_cals![i-1] as? Event_Cal ?? ec_del
                                                    viewModel.highlightedSC = nil
                                                }
                                                else if i + 1 < size {
                                                    viewModel.highlightedEC = ec_del.section_cal?.event_cals![i+1] as? Event_Cal ?? ec_del
                                                    viewModel.highlightedSC = nil
                                                }
                                                else {
                                                    viewModel.highlightedEC = nil
                                                    viewModel.highlightedSC = currentSC
                                                }
                                            }
                                        }

                                        ec_del.delete()
                                        viewModel.showEventDetail = false
                                    }
                                },
                                secondaryButton: .cancel()
                            )
                        case .deleteSection(_):
                            return Alert(
                                title: Text("Error"),
                                message: Text("Are you sure you want to delete this Section?"),
                                primaryButton: .destructive(Text("Delete")) {

                                },
                                secondaryButton: .cancel()
                            )
                        }
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
                        // Create empty section at the bottom
                        toDoForDate.first?.addSection()
                        viewModel.refresh.toggle()
                    }
                    //Padding at the bottom to allow Users to scroll down, for planning page needs more
                    .padding(.bottom, 125)
                    .padding(.horizontal, K.horizontal_padding)
                }
                .scrollIndicators(.hidden)
                .onChange(of: date) {
                    if pos == .centerView{
                        dayPlannerVM.setCurrentDate(to: date)
                    }
                }
                .onChange(of: viewModel.refresh) { _, _ in
                    withAnimation {
                        LiveActivityActions.refreshLiveActivities()
                    }
                }
                .onChange(of: toDoForDate.first) { _, _ in
                    //sort everytime something changes
                    withAnimation {
                        LiveActivityActions.refreshLiveActivities()
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
                .onChange(of: viewModel.highlightedSC) { _, _ in
                    withAnimation {
                        if pos == .centerView{
                            proxy.scrollTo(viewModel.highlightedSC?.id, anchor: .top)
                        }
                    }
                }
            }
        }
    }

    func edit(sc: Section_Cal){
        viewModel.showSelectSection = true
        viewModel.changeSection_Cal = sc
        viewModel.changeSection = nil
        viewModel.insertToCal = toDoForDate.first ?? Cal.getOrCreateWithDefault(date: date)
    }

}

enum ActiveAlert: Identifiable {
    case deleteSectionCal(Section_Cal)
    case deleteSection(Section)
    case deleteEvent(Event_Cal)

    var id: String {
        switch self {
        case .deleteSection(let s): return "deleteSection-\(s.objectID)"
        case .deleteSectionCal(let sc): return "deleteSection-\(sc.objectID)"
        case .deleteEvent(let ec): return "deleteEvent-\(ec.objectID)"
        }
    }
}
