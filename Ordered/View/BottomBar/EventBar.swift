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

    @FetchRequest private var otherEvents: FetchedResults<Event>

    @FetchRequest(
        sortDescriptors: [SortDescriptor(\Section.order, order: .forward)],
        predicate: NSPredicate(format: "isActive == true")
    ) private var sections: FetchedResults<Section>

    @FetchRequest(
        sortDescriptors: [SortDescriptor(\Category.order, order: .forward)],
        predicate: NSPredicate(format: "isActive == true")
    ) private var categories: FetchedResults<Category>

    @State private var editingSection: Section?
    @State private var showSectionEditor = false

    @State var overlayHeight: CGFloat = UIScreen.main.bounds.height * 0.2
    @State var lastHeight: CGFloat = UIScreen.main.bounds.height * 0.2
    @GestureState private var dragOffset: CGFloat = 0

    let dismissHeight: CGFloat = 0
    let minHeight: CGFloat = UIScreen.main.bounds.height * 0.2
    let midHeight: CGFloat = UIScreen.main.bounds.height * 0.5

    @State private var selection = "Section"
    let options = ["Section", "Event"]

    init(viewModel: ContentViewModel, dayPlannerVM: DayPlannerViewModel) {
        self.viewModel = viewModel
        self.dayPlannerVM = dayPlannerVM

        _otherEvents = FetchRequest(
            sortDescriptors: [
                SortDescriptor(\.isFavourite, order: .reverse),
                SortDescriptor(\.order, order: .forward)
            ],
            predicate: NSPredicate(format: "isActive == true")
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
                .showCase(order: 3, title: "Select Section or Event", cornerRadius: 20){
                    selection = "Event"
                }
            }
            .padding(.vertical)
            .padding(.horizontal, K.horizontal_padding)
            .background(.color2)


            //Events
            ScrollView{

                if selection == "Event"{
                    ForEach(categories) { category in
                        categoryGroup(category)
                    }

                    eventGroup(
                        title: "Uncategorized",
                        icon: "tray",
                        events: uncategorizedEvents
                    )
                }


                else if selection == "Section" {
                    LazyVGrid(columns: [GridItem(), GridItem()],spacing: K.horizontal_padding, content: {
                        ForEach(sections) { section in
                            SectionInfo(section: section)
                                .padding(.horizontal)
                                .onTapGesture {
                                    withAnimation {
                                        HapticFeedback.light()
                                        if viewModel.currentTab == .plan {
                                            let cal = Cal.get(date: dayPlannerVM.currentDate.getYYMMDD()) ?? Cal.new(date: dayPlannerVM.currentDate.getYYMMDD())
                                            let newSection = section.getSC()

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
                                                cal.addSection(newSection)
                                                viewModel.highlightedSC = newSection
                                                viewModel.highlightedEC = nil
                                            }

                                            viewModel.refresh.toggle()
                                        }
                                    }
                                }
                                .contextMenu {
                                    Button("Edit", systemImage: "pencil") {
                                        editingSection = section
                                        showSectionEditor = true
                                    }
                                    Button("Delete", systemImage: "trash", role: .destructive) {
                                        section.delete()
                                        viewModel.refresh.toggle()
                                    }
                                }
                        }

                        Button {
                            editingSection = nil
                            showSectionEditor = true
                        } label: {
                            newItemTile("New Section")
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
        .sheet(isPresented: $showSectionEditor) {
            SectionEditor(section: editingSection) { viewModel.refresh.toggle() }
        }
    }

    private var uncategorizedEvents: [Event] {
        otherEvents.filter { $0.activeCategories.isEmpty }
    }

    private func categoryEvents(_ category: Category) -> [Event] {
        (category.events?.array as? [Event] ?? []).filter(\.isActive)
    }

    private func eventIndex(_ event: Event) -> Int {
        otherEvents.firstIndex(where: { $0 == event }) ?? 2
    }

    private func categoryGroup(_ category: Category) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(category.icon ?? "🏷️")
                Text(category.name ?? "Category")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, K.horizontal_padding)

            Rectangle()
                .fill(Color.color3)
                .frame(height: 2)
                .padding(.horizontal, K.horizontal_padding)

            if categoryEvents(category).isEmpty {
                Text("No events")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, K.horizontal_padding)
            } else {
                eventGrid(categoryEvents(category))
            }
        }
        .padding(.bottom, 20)
    }

    private func eventGroup(title: String, icon: String, events: [Event]) -> some View {
        VStack(spacing: 8) {
            Label(title, systemImage: icon)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, K.horizontal_padding)

            Rectangle()
                .fill(Color.color3)
                .frame(height: 2)
                .padding(.horizontal, K.horizontal_padding)

            eventGrid(events, includesNewEvent: true)
        }
        .padding(.bottom, 12)
    }

    private func eventGrid(_ events: [Event], includesNewEvent: Bool = false) -> some View {
        LazyVGrid(columns: [GridItem(), GridItem()], spacing: K.horizontal_padding) {
            ForEach(events) { event in
                EventInfo(e: event)
                    .padding(.horizontal)
                    .modifier(
                        EventTapModifier(
                            event: event,
                            index: eventIndex(event),
                            viewModel: viewModel,
                            dayPlannerVM: dayPlannerVM
                        )
                    )
            }

            if includesNewEvent {
                Button {
                    viewModel.editEvent_Cal = nil
                    viewModel.createEvent_Section_Cal = nil
                    viewModel.createEvent_Section = nil
                    viewModel.showCreateEvent = true
                } label: {
                    newItemTile("New Event")
                }
            }
        }
    }

    private func newItemTile(_ title: String) -> some View {
        HStack {
            Image(systemName: "plus.circle.fill")
                .font(.title)
            Text(title)
                .font(.title3)
            Spacer()
        }
        .foregroundStyle(.black)
        .padding(.horizontal)
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
                    cal.addSection(new_section_Cal)
                    viewModel.highlightedEC = newEC
                    viewModel.highlightedSC = nil
                }

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
