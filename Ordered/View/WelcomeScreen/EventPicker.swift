//
//  EventPicker.swift
//  Ordered
//
//  Created by Kai Hin Hung on 31/8/2024.
//

import SwiftUI

struct EventPicker: View {
    
    var sectionName: String
//    @FetchRequest private var fetchedSection: FetchedResults<Section>
    @Binding var selectedEvents: [Event]
    
    @State var draggingItem: Event? = nil
    
    init(sectionName: String, selectedEvents: Binding<[Event]>) {
        self.sectionName = sectionName
        self._selectedEvents = selectedEvents
        
//        _fetchedSection = FetchRequest<Section>(
//            entity: Section.entity(),
//            sortDescriptors: [],
//            predicate: NSPredicate(format: "name == %@", sectionName)
//        )
    }
    
    @State var refreshId = UUID()
    
    var body: some View {
        ScrollView{
            VStack{
                HStack(alignment: .bottom){
                    
//                    Text(fetchedSection.first!.name ?? "")
//                        .font(.title3)
//                        .bold()
                    
                    Spacer()
                    
//                    Circle()
//                        .fill(Color(hex: fetchedSection.first!.color))
//                        .frame(width: K.medium_size, height: K.medium_size)
//                        .overlay{
//                            ColorPicker("", selection: .constant(Color(hex: fetchedSection.first!.color))).labelsHidden().opacity(0.015)
//                        }
                }
                
                Divider()
                    .background(Color.blue)
                    .frame(height: 2)
                    .padding(.top, -8)
                
//                ForEach(fetchedSection.first!.events?.array as! [Event], id: \.self){ e in
//                    HStack{
//                        EventInfo(s: fetchedSection.first!, e: e)
//                        
//                        Spacer()
//                        
//                        ZStack{
//                            Circle()
//                                .fill(.color1)
//                                .frame(height: K.medium_size)
//                            
//                            if selectedEvents.contains(e){
//                                Image(systemName: "checkmark")
//                                    .transition(.scale)
//                            }
//                        }
//                    }
//                    .background()
//                    .onTapGesture {
//                        if !selectedEvents.contains(e){
//                            withAnimation (.easeInOut(duration: 0.2)) {
//                                selectedEvents.append(e)
//                            }
//                            
//                        }
//                        else{
//                            withAnimation (.easeInOut(duration: 0.2)) {
//                                selectedEvents.removeAll { $0 == e }
//                            }
//                        }
//                    }
//                    .opacity(selectedEvents.contains(e) ? 1 : 0.5)
//                    
//                    //For dragging capability
//                    .dropDestination(for: String.self) { items, location in
//                        draggingItem = nil
//                        return false
//                    } isTargeted: { status in
//                        if let draggingItem, status, draggingItem.description != e.description{
//                            
//                            if let events = fetchedSection.first?.events?.mutableCopy() as? NSMutableOrderedSet {
//                                let e_index = events.index(of: e)
//                                let d_index = events.index(of: draggingItem)
//                                
//                                if e_index != d_index{
//                                    events.remove(draggingItem)
//                                    events.insert(draggingItem, at: e_index)
//                                }
//                                
//                                fetchedSection.first?.events = events.copy() as? NSOrderedSet
//                            }
//                            
//                            do{
//                                try PersistenceController.shared.container.viewContext.save()
//                            }
//                            catch{
//                                fatalError("unresolved error \(error)")
//                            }
//                        }
//                    }
//                    .draggable(e.description){
//                        Image(systemName: "pencil")
//                            .onAppear {
//                                draggingItem = e
//                            }
//                    }
//                    
//                }
                
            }
            
        }
    }
}
