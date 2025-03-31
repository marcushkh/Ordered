//
//  EventList.swift
//  Ordered
//
//  Created by Kai Hin Hung on 18/2/2025.
//

import SwiftUI
import CoreData

struct EventList: View {
    @ObservedObject var viewModel: ContentViewModel
    
    @State var allEvents: [Event] = []
    @Binding var eventName: String
    @Binding var selectedEvent: Event?
    
    @State var draggingItem: Event? = nil
    var isChangeSelectedEvent: Bool
    
    @State var refresh: Bool = false
    
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
                            
                            Image(systemName: "pencil.line")
                                .onTapGesture {
                                    viewModel.showChangeEvent = true
                                    viewModel.changeEvent = e
                                }
                            
                            Image(systemName: e.isFavourite ? "heart.fill" : "heart")
                                .bold()
                                .foregroundStyle(.heart)
                                .onTapGesture {
                                    withAnimation {
                                        e.toggleIsFavorite()
                                        if isChangeSelectedEvent{
                                            selectedEvent = e
                                        }
                                        fetchEvents()
                                        saveOrder()
                                        refresh.toggle()
                                    }
                                }
                                .onChange(of: refresh) { _, _ in
                                    
                                }
                        }
                        .padding(.horizontal)
                        
                    }
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
                            draggingItem = e
                        }
                    }
                    .dropDestination(for: String.self) { items, location in
                        draggingItem = nil
                        refresh.toggle()
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
                                refresh.toggle()
                            }
                        }
                    }
                }
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
            }
        }
    }
    private func fetchEvents() {
        let request: NSFetchRequest<Event> = Event.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Event.isFavourite, ascending: false),
            NSSortDescriptor(keyPath: \Event.order, ascending: true)
        ]
        if !eventName.isEmpty {
            request.predicate = NSPredicate(format: "name BEGINSWITH[c] %@", eventName)
        }

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
