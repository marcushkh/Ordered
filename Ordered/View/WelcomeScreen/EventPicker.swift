//
//  EventPicker.swift
//  Ordered
//
//  Created by Kai Hin Hung on 31/8/2024.
//

import SwiftUI

struct EventPicker: View {
    
    var sectionName: String
    @FetchRequest private var fetchedSection: FetchedResults<Section>
    @Binding var selectedEvents: [Event]
    
    init(sectionName: String, selectedEvents: Binding<[Event]>) {
        self.sectionName = sectionName
        self._selectedEvents = selectedEvents
        
        _fetchedSection = FetchRequest<Section>(
            entity: Section.entity(),
            sortDescriptors: [],
            predicate: NSPredicate(format: "name == %@", sectionName)
        )
    }
    
    @State var refreshId = UUID()
    
    var body: some View {
        ScrollView{
            VStack{
                HStack(alignment: .bottom){
                    
                    Text(fetchedSection.first!.name ?? "")
                        .font(.title3)
                        .bold()
                    
                    Spacer()
                    
                    Circle()
                        .fill(Color(hex: fetchedSection.first!.color))
                        .frame(width: K.medium_size, height: K.medium_size)
                        .overlay{
                            ColorPicker("", selection: .constant(Color(hex: fetchedSection.first!.color))).labelsHidden().opacity(0.015)
                        }
                }
                
                Divider()
                    .background(Color.blue)
                    .frame(height: 2)
                    .padding(.top, -8)
                
                ForEach(fetchedSection.first!.events?.array as! [Event], id: \.self){ e in
                    HStack{
                        EventInfo(s: fetchedSection.first!, e: e)
                        
                        Spacer()
                        
                        ZStack{
                            Circle()
                                .fill(.color1)
                                .frame(height: K.medium_size)
                            
                            if selectedEvents.contains(e){
                                Image(systemName: "checkmark")
                                    .transition(.scale)
                            }
                        }
                    }
                    .background()
                    .onTapGesture {
                        if !selectedEvents.contains(e){
                            withAnimation {
                                selectedEvents.append(e)
                            }
                            
                        }
                        else{
                            withAnimation {
                                selectedEvents.removeAll { $0 == e }
                            }
                        }
                        
                    }
                }
                
            }
            
        }
    }
}
