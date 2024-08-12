//
//  MainList.swift
//  Ordered
//
//  Created by Kai Hin Hung on 1/8/2024.
//

import SwiftUI

struct MainList: View {

    @FetchRequest(
        sortDescriptors: []
//        predicate: NSPredicate(format: "date == %@", Date() as NSDate)
    )
    private var calendar: FetchedResults<Cal>
    
    var body: some View {
        if calendar.first != nil{
            ForEach(calendar.first?.sections?.array as! [Section_Cal], id: \.self){ 
                sc in
                let section = sc.parent
                
                VStack{
                    //Section Header
                    HStack(alignment: .bottom){
                        
                        Text(section?.name ?? "")
                            .font(.title3)
                            .bold()
                        
                        Spacer()
                        
                        Circle()
                            .fill(Color(hex: section?.color))
                            .frame(width: K.medium_size, height: K.medium_size)
                            .overlay{
                                ColorPicker("", selection: .constant(Color(hex: section?.color))).labelsHidden().opacity(0.015)
                            }
                        
                    }
                    
                    Divider()
                        .background(Color.blue)
                        .frame(height: 2)
                        .padding(.top, -8)
                    
                    //Events
                    ForEach(sc.events?.array as! [Event_Cal], id: \.self){ ec in
                        let event = ec.parent
                    
                        HStack{
                            ZStack{
                                Circle()
                                    .fill(Color(hex: section?.color))
                                    .frame(height: K.xlarge_size)
                                
                                Text(event?.icon ?? "")
                                    .font(.custom("", size: K.large_size))
                                    .shadow(radius: K.medium_size)
                            }
                            .padding(.trailing)
                            
                            VStack(alignment: .leading){
                                Text(event?.name ?? "")
                                    .font(.title3)
                                
                                if event?.duration != -1 {
                                    Text(String(event?.duration ?? 0))
                                        .font(.callout)
                                        .foregroundStyle(.secondary)
                                }
                                
                            }
                            
                            Spacer()
                            
                            ZStack{
                                Circle()
                                    .fill(.color1)
                                    .frame(height: K.medium_size)
                                
                                Image(systemName: event?.duration == -1 ? "checkmark" : "play")
                            }
                        }
                    }
                }
                .padding(.vertical)
                .padding(.horizontal, K.horizontal_padding)
            }
        }
    }
}

#Preview {
    MainList()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
