//
//  EventBar.swift
//  Ordered
//
//  Created by Kai Hin Hung on 5/8/2024.
//

import SwiftUI

struct EventBar: View {
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.order, order: .forward)],
        predicate: NSPredicate(format: "isActive == true")
    )
    private var events: FetchedResults<Event>
    
    var body: some View {
        VStack(spacing: 0){
            HStack{
                Text("New")
                    .bold()
                
                Spacer()
                
                Menu {
                    Button {
                        
                    } label: {
                        Text("Event")
                    }
                    Button {
                        
                    } label: {
                        Text("Section")
                    }
                    Button {
                        
                    } label: {
                        Text("Day")
                    }
                } label: {
                    HStack{
                        Text("Event")
                            .bold()
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .padding(.leading, -5)
                            .bold()
                    }
                }
                
                Spacer()
                
                Text("Edit")
                    .bold()
            }
            .padding(.vertical)
            .padding(.horizontal, K.horizontal_padding)
            .padding(.bottom)
            .background(.color2)
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 30, topTrailingRadius: 30))
            
            //Events
            ScrollView{
                LazyVGrid(columns: [GridItem(), GridItem()],spacing: K.horizontal_padding, content: {
                    ForEach(events) { event in
                        
                        HStack{
                            ZStack{
                                Circle()
                                    .fill(.color1)
                                    .frame(width: K.large_size)
                                
                                Text(event.icon ?? "")
                                    .font(.title)
                                    .shadow(radius: 10)
                            }
                            
                            VStack(alignment: .leading){
                                Text(event.name ?? "")
                                
                                Text(String(event.duration))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                        
                        
                    }
                })
            }
            .frame(height: UIScreen.main.bounds.height * 0.2)
            .background(.color2)
        }
        
    }
}
#Preview {
    VStack{
        Spacer()
        EventBar()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
