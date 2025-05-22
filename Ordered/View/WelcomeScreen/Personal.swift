//
//  MorningRoutineCase.swift
//  Ordered
//
//  Created by Kai Hin Hung on 29/8/2024.
//

import SwiftUI
import MCEmojiPicker

struct Personal: View {
    
    @ObservedObject var welcomeVM: WelcomeVM
    @ObservedObject var viewModel: ContentViewModel
    
    @FetchRequest(
        entity: Event.entity(), sortDescriptors: [],
        predicate: NSPredicate(format: "isActive == true")
    ) private var events: FetchedResults<Event>
    
    @State var isExpanded = true
    @State var icon = "💡"
    @State var eventName = ""
    @FocusState var eventTyping: Bool
    
    
    
    
    var body: some View {
        Background(color: .cBackground, allFocusStates: [$eventTyping]){
            VStack(alignment: .leading){
                HStack{
                    Spacer()
                    VStack{
                        Text("What is your")
                            .font(.title2)
                            .bold()
                        
                        Text("Most Important 2 Projects")
                            .font(.title2)
                            .bold()
                            .padding(.bottom)
                    }
                    Spacer()
                }
                
                Text("""
                There must be some projects you always wanted to do after school / work.
                """)
                .foregroundStyle(.gray)
                .font(.subheadline)
                .padding(.bottom, 4)
                .onTapGesture {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }
                
                if isExpanded{
                    Text("""
                • Create your own start-up bussiness 🚀
                • Finish Your Freelance Job 💼
                • Launch a YouTube channel or podcast 🎙️
                • Learn a new language 🗣️
                • Learn guitar or another instrument 🎸     
                • Sell art, crafts, or digital products 🎨  
                """)
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
                    .onTapGesture {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    }
                }
                
                
                Divider()
                    .foregroundStyle(.color3)
                
                
                EventList(viewModel: viewModel, eventName: .constant(""), selectedEvent: .constant(nil), toggleHeartSelectEvent: false, showHeart: false, showEdit: true, showDelete: true) {
                    
                    if (events.count < 2) {
                        ZStack{
                            RoundedRectangle(cornerRadius: 20.0)
                                .fill(.color1)
                            
                            HStack{
                                EventAndEmoji(eventName: $eventName, selectedEmoji: $icon, eventNameTyping: $eventTyping) {
                                    Text(icon)
                                        .font(.title)
                                } eventNameView: {
                                    TextField("Event Name", text: $eventName)
                                        .focused($eventTyping)
                                        .font(.title3)
                                }
                                
                                Spacer()
                                
                                Button{
                                    if eventName.isEmpty{
                                        eventTyping = true
                                    }
                                    else{
                                        Event.save(icon: icon, name: eventName, duration: 30, order_insert_first: false)
                                        icon = "💡"
                                        eventName = ""
                                        
                                        viewModel.refresh.toggle()
                                    }
                                    
                                } label:{
                                    Image(systemName: "plus.circle.fill")
                                        .bold()
                                        .foregroundStyle(.cPrimary, .success)
                                }
                                
                            }
                            .frame(height: 60)
                            .padding(.horizontal)
                        }
                    }
                }
                
            }
            .onChange(of: viewModel.refresh, { oldValue, newValue in
                
            })
            .onChange(of: eventTyping, { oldValue, newValue in
                if eventTyping{
                    withAnimation {
                        isExpanded = false
                    }
                }
            })
            .onDisappear{
                if !eventName.isEmpty{
                    Event.save(icon: icon, name: eventName, duration: 30, order_insert_first: false)
                    icon = "💡"
                    eventName = ""
                    
                    viewModel.refresh.toggle()
                }
            }
            .padding(.top)
        }
    }
}
