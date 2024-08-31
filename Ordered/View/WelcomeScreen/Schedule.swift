//
//  Schedule.swift
//  Ordered
//
//  Created by Kai Hin Hung on 31/8/2024.
//

import SwiftUI
import PopupView

struct Schedule: View {
    
    @ObservedObject var welcomeVM: WelcomeVM
    
    @FetchRequest<Section>(
        sortDescriptors: [],
        predicate: NSPredicate(format: "name == %@", "Schedule")
    )
    var fetchedSection: FetchedResults<Section>
    
    var body: some View {
        VStack(alignment: .leading){
            Text("Design Your Dream Day")
                .font(.title2)
                .bold()
            Text("All Your Schedule Will Be Placed Here")
                .font(.title2)
                .bold()
                .padding(.bottom)
            
            ScrollView{
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
                        HStack{
                            ZStack{
                                Circle()
                                    .fill(Color(hex: fetchedSection.first!.color))
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
                            
                            if welcomeVM.scheduleEvents.contains(e){
                                Image(systemName: "checkmark")
                                    .transition(.scale)
                            }
                        }
                    }
                    .background()
                    .onTapGesture {
                        if !welcomeVM.scheduleEvents.contains(e){
                            withAnimation {
                                welcomeVM.selectedEvent = e
                                welcomeVM.showSelectTime = true
                            }
                        }
                        else{
                            withAnimation {
                                welcomeVM.scheduleEvents.removeAll { $0 == e }
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
    Schedule(welcomeVM: WelcomeVM())
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
