//
//  CreateEvent.swift
//  Ordered
//
//  Created by Kai Hin Hung on 18/10/2024.
//

import SwiftUI
import MCEmojiPicker


struct CreateEvent: View {
    @State var isPresented: Bool = false
    @State var selectedEmoji: String = "🥱"
    
    @State var eventName: String = ""
    @FocusState var eventNameTyping
    
    @State var isSchedule: Bool = false
    @State private var startTime = Date()
    
    @State var isDuration: Bool = false
//    @State var duration: String = ""
    
    var body: some View {
        Background(color: Color(.white), allFocusStates: [$eventNameTyping]){
            VStack{
                HStack{
                    ZStack{
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.color1))
                            .frame(width: 60, height: 60)
                        
                        Text(selectedEmoji)
                            .font(.custom("", size: 50))
                            .shadow(radius: K.medium_size)
                            .onTapGesture {
                                isPresented.toggle()
                            }
                            .emojiPicker(
                                isPresented: $isPresented,
                                selectedEmoji: $selectedEmoji
                            )
                    }
//                    .padding(.trailing)
                    Spacer()
                    
                    TextField("", text: $eventName)
                        
                        .multilineTextAlignment(.leading)
                        .placeholder(when: eventName.isEmpty, alignment: .leading, placeholder: {
                            Text("Event").foregroundStyle(.secondary)
                        })
                        .focused($eventNameTyping)
                        .multilineTextAlignment(.trailing)
                        .underlineTextField(underline: .color3, focus: eventNameTyping, focusColor: Color(.color2))
                        .font(.system(size: 24))
                        .frame(width: 228, height: 80)
                }
                .padding(.bottom)
                
                //Start End Time
                VStack{
                    Toggle(isOn: $isSchedule) {
                        Text("Schedule")
                            .font(.system(size: 20))
                            .bold()
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .color3))
                    
                    ZStack{
                        RoundedRectangle(cornerRadius: 10)
//                            .stroke(.color3, lineWidth: 2)
                            .fill(.color1)
//                            .shadow(radius: 5)
                            .frame(height: 90)
                            
                        VStack{
                            DatePicker("Start Time: ", selection: $startTime, displayedComponents: .hourAndMinute)
                                .padding(.horizontal)
                            
                            DatePicker("End Time: ", selection: $startTime, displayedComponents: .hourAndMinute)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .padding(.bottom)
                
                //Duration
                VStack{
                    Toggle(isOn: $isDuration) {
                        Text("Duration")
                            .font(.system(size: 20))
                            .bold()
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .color3))
                }
                
                Spacer()
            }
            .padding(.horizontal, K.horizontal_padding * 2)
            
        }
    }
}

#Preview {
    CreateEvent()
}
