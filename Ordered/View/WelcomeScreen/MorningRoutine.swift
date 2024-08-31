//
//  MorningRoutineCase.swift
//  Ordered
//
//  Created by Kai Hin Hung on 29/8/2024.
//

import SwiftUI

struct MorningRoutine: View {
    
    @FetchRequest(
        sortDescriptors: []
//        predicate: NSPredicate(format: "name == %@", "Morning Routine")
    )
    private var fetchedSection: FetchedResults<Section>
    
    @State var selection: [Event] = []
    
    var body: some View {
        let s: Section = fetchedSection.first!
        
        VStack(alignment: .leading){
            Text("Design Your Dream Day")
                .font(.title2)
                .bold()
            Text("A Good Day Starts Every Morning")
                .font(.title2)
                .bold()
                .padding(.bottom)
            
            ScrollView{
                VStack{
                    HStack(alignment: .bottom){
                        
                        Text(s.name ?? "")
                            .font(.title3)
                            .bold()
                        
                        Spacer()
                        
                        Circle()
                            .fill(Color(hex: s.color))
                            .frame(width: K.medium_size, height: K.medium_size)
                            .overlay{
                                ColorPicker("", selection: .constant(Color(hex: s.color))).labelsHidden().opacity(0.015)
                            }
                    }
                    
                    Divider()
                        .background(Color.blue)
                        .frame(height: 2)
                        .padding(.top, -8)
                    
                    ForEach(s.events?.array as! [Event], id: \.self){ e in
                        HStack{
                            HStack{
                                ZStack{
                                    Circle()
                                        .fill(Color(hex: s.color))
                                        .frame(height: K.xlarge_size)
                                    
                                    Text(e.icon ?? "")
                                        .font(.custom("", size: K.large_size))
                                        .shadow(radius: K.medium_size)
                                }
                                .padding(.trailing)
                                
                                VStack(alignment: .leading){
                                    Text(e.name ?? "")
                                        .font(.title3)
                                    
                                    if e.duration != -1 {
                                        Text(String(e.duration) + " min")
                                            .font(.callout)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                }
                            }
                            
                            Spacer()
                            
                            ZStack{
                                Circle()
                                    .fill(.color1)
                                    .frame(height: K.medium_size)
                                
                                if selection.contains(e){
                                    Image(systemName: "checkmark")
                                        .transition(.scale)
                                }
                            }
                        }
                        .onTapGesture {
                            if !selection.contains(e){
                                withAnimation {
                                    selection.append(e)
                                }
                                
                            }
                            else{
                                withAnimation {
                                    selection.removeAll { $0 == e }
                                }
                            }
                            
                        }
                    }
                }
                
            }
        }
        .padding(.top)
    }
}

#Preview {
    MorningRoutine()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
