//
//  EventList.swift
//  Ordered
//
//  Created by Kai Hin Hung on 18/2/2025.
//

import SwiftUI
import CoreData

struct EventList<Content: View>: View {
    @ObservedObject var viewModel: ContentViewModel
    
    @State var allEvents: [Event] = []
    @Binding var eventName: String
    @Binding var selectedEvent: Event?
    
    @State var draggingItem: Event? = nil
    
    var toggleHeartSelectEvent: Bool
    
    var customPredicate: NSPredicate?
    var showHeart: Bool
    var showEdit: Bool
    var showLocation: Bool
    var showDelete: Bool
    
    var content: Content
    
    init(
        viewModel: ContentViewModel,
        eventName: Binding<String>,
        selectedEvent: Binding<Event?>,
        toggleHeartSelectEvent: Bool = false,
        customPredicate: NSPredicate? = nil,
        showHeart: Bool = true,
        showEdit: Bool = true,
        showLocation: Bool = false,
        showDelete: Bool = false,
        @ViewBuilder content: () -> Content = { EmptyView() }
    ) {
        self.viewModel = viewModel
        self._eventName = eventName
        self._selectedEvent = selectedEvent
        self.toggleHeartSelectEvent = toggleHeartSelectEvent
        self.customPredicate = customPredicate
        self.showHeart = showHeart
        self.showEdit = showEdit
        self.showLocation = showLocation
        self.showDelete = showDelete
        self.content = content()
    }
    
    var body: some View{
        ScrollView{
            VStack{
                ForEach(allEvents, id:\.self){ e in
                    ZStack{
                        RoundedRectangle(cornerRadius: 20.0)
                            .fill(.color1)
                        
                        HStack{
                            
                            EventInfo(e: e)
                            
                            Spacer()
                            
                            if showEdit{
                                Button{
                                    HapticFeedback.light()
                                    viewModel.showChangeEvent = true
                                    viewModel.changeEvent = e
                                } label:{
                                    Image(systemName: "pencil.line")
                                        .foregroundStyle(.cPrimary)
                                }
                            }
                            
                            if showHeart{
                                Button{
                                    withAnimation {
                                        HapticFeedback.light()
                                        e.toggleIsFavorite()
                                        
                                        if toggleHeartSelectEvent{
                                            selectedEvent = e
                                        }
                                        fetchEvents()
                                        saveOrder()
                                        viewModel.refresh.toggle()
                                    }
                                } label:{
                                    Image(systemName: e.isFavourite ? "heart.fill" : "heart")
                                        .bold()
                                        .foregroundStyle(.heart)
                                }
                            }
                            
                            if showLocation{
                                let locationSet = e.locations
                                let sortedLocations = (locationSet?.allObjects as? [Location] ?? [])
                                    .sorted { $0.positionOrder < $1.positionOrder }
                                ForEach(sortedLocations, id: \.self) { location in
                                    Image(location.imageName ?? "")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: K.medium_size)
                                }
                            }
                            
                            if showDelete{
                                Button{
                                    withAnimation {
                                        print("delete")
                                        e.delete()
                                        fetchEvents()
                                        saveOrder()
                                        viewModel.refresh.toggle()
                                    }
                                    
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .bold()
                                        .foregroundStyle(Color.cPrimary, Color.error)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 20.0)
                            .stroke(selectedEvent == e ? Color.color3 : Color.clear, lineWidth: 3)
                    )
                    .frame(height: 60)
                    .onTapGesture {
                        withAnimation {
                            selectedEvent = e
                        }
                    }
                    .draggable(e.description){
                        ZStack{
                            Circle()
                                .frame(height: K.xlarge_size)
                            
                            Text(e.icon ?? "")
                                .font(.custom("", size: K.large_size))
                                .shadow(radius: K.medium_size)
                            
                        }
                        .onAppear {
                            HapticFeedback.light()
                            draggingItem = e
                        }
                    }
                    .dropDestination(for: String.self) { items, location in
                        draggingItem = nil
                        viewModel.refresh.toggle()
                        return false
                    } isTargeted: { status in
                        
                        withAnimation {
                            //Reordering
                            if let draggingItem, status, draggingItem.objectID != e.objectID{
                                let e_index = allEvents.firstIndex(of: e) ?? 0
                                
                                allEvents.remove(at: allEvents.firstIndex(of: draggingItem) ?? 0)
                                allEvents.insert(draggingItem, at: e_index)
                                
                                allEvents = allEvents.sorted { $0.isFavourite && !$1.isFavourite  }
                                
                                saveOrder()
                                viewModel.refresh.toggle()
                            }
                        }
                    }
                }
                
                content
            }
            .padding(.horizontal, 3)
            .padding(.top, 3)
        }
        .scrollIndicators(.hidden)
        .onChange(of: viewModel.refresh) { _, _ in
            withAnimation {
                fetchEvents()
                saveOrder()
            }
        }
        .onChange(of: eventName) { _, _ in
            withAnimation {
                fetchEvents()
            }
        }
        .onAppear {
            withAnimation {
                fetchEvents()
                saveOrder()
            }
        }
        
        
    }
    private func fetchEvents() {
        let request: NSFetchRequest<Event> = Event.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Event.isFavourite, ascending: false),
            NSSortDescriptor(keyPath: \Event.order, ascending: true)
        ]
        
        var predicates = NSPredicate(format: "isActive == true")
        
        if !eventName.isEmpty {
            predicates = NSCompoundPredicate(type: .and, subpredicates: [predicates, NSPredicate(format: "name CONTAINS[c] %@", eventName)])
        }
        
        if let p = customPredicate{
            predicates = NSCompoundPredicate(type: .and, subpredicates: [predicates, p])
        }
        
        request.predicate = predicates
        
        do {
            allEvents = try Model.viewContext.fetch(request)
        } catch {
            print("Fetch failed: \(error)")
        }
    }
    
    private func saveOrder() {
        for i in allEvents{
            i.order = Int16(allEvents.firstIndex(of: i) ?? 0)
        }
        do{
            try PersistenceController.shared.container.viewContext.save()
        }
        catch{
            fatalError("unresolved error \(error)")
        }
    }
}
