//
//  CreateEvent.swift
//  Ordered
//
//  Created by Kai Hin Hung on 18/10/2024.
//

import SwiftUI
import MCEmojiPicker

 
struct CreateEvent: View {
    @Namespace private var underlineNamespace
    
    @State var isPresented: Bool = false
    @State var selectedEmoji: String = "🥱"
    
    @State var eventName: String = ""
    @FocusState var eventNameTyping
    
    @State var isSchedule: Bool = false
    @State private var startTime = Date()
    @State private var endTime: Date = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    
    @State var isDuration: Bool = false
    @State private var selectedIndex: Int = 0
    private let durationOptions = ["5m", "10m", "30m", "1h", "More"]
    
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
                            .fill(.color1)
                            .shadow(radius: isSchedule ? 1 : 0)
                            .frame(height: 100)
                            
                        VStack{
                            DatePicker("Start Time: ", selection: $startTime, displayedComponents: .hourAndMinute)
                                .padding(.horizontal)
                                .tint(.color4)
                                .onChange(of: startTime) { oldValue, newValue in
                                    if newValue >= endTime {
                                        endTime = Calendar.current.date(byAdding: .hour, value: 1, to: newValue) ?? newValue
                                    }
                                }
                            
                            DatePicker("End Time: ", selection: $endTime, displayedComponents: .hourAndMinute)
                                .padding(.horizontal)
                                .tint(.color4)
                                .onChange(of: endTime) { oldValue, newValue in
                                    if newValue <= startTime {
                                        startTime = Calendar.current.date(byAdding: .hour, value: -1, to: newValue) ?? newValue
                                    }
                                }
                                
                        }
                    }
                    .padding(.vertical, 8)
                    .opacity(isSchedule ? 1 : 0.5)
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
                    
                    ZStack{
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.color1)
                            .frame(height: 60)
                            .shadow(radius: isDuration ? 1 : 0)
                        
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5)) {
                            ForEach(0..<durationOptions.count, id: \.self) { index in
                                ZStack {
                                    if selectedIndex == index {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(.white)
                                            .frame(height: 40)
                                            .matchedGeometryEffect(id: "underline", in: underlineNamespace)
                                    }
                                    
                                    Text(durationOptions[index])
                                        .foregroundColor(selectedIndex == index ? .color3 : .gray)
                                        .onTapGesture {
                                            withAnimation {
                                                selectedIndex = index
                                            }
                                        }
                                    
                                    
                                }
                            }
                            
                        }
                        .padding()
                    }
                    .opacity(isDuration ? 1 : 0.5)
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
