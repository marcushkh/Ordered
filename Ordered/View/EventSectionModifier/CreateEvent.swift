//
//  CreateEvent.swift
//  Ordered
//
//  Created by Kai Hin Hung on 18/10/2024.
//

import SwiftUI
import MCEmojiPicker
 
struct CreateEvent: View {
    @State var editEvent_Cal: Event_Cal? = nil
    @Namespace private var underlineNamespace
    
    @State var date: Date = Date()
    @State var section_Cal: Section_Cal? = nil
    
    @State var showEmojiPicker: Bool = false
    @State var selectedEmoji: String = "💡"
    @State var emojiPickerPicked: String = "💡"
    @State var giveSuggestion: Bool = true
    
    @State var eventName: String = ""
    @FocusState var eventNameTyping
    
    @State var isSchedule: Bool = false
    @State private var startTime = Date()
    @State private var endTime: Date = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    
    @State var isDuration: Bool = false
    
    @State private var selectedIndex: Int = 0
    private let durationOptions = ["5m", "10m", "30m", "1h"]
    
    @State var showCustomDuration: Bool = false
    @State var useCustomDuration: Bool = false
    @State private var customDuration: Int = 90
    
    let data = DataLoader()
    @State private var debounceTask: Task<Void, Never>? = nil
    @Binding var display: Bool
    
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
                                showEmojiPicker.toggle()
                            }
                            .emojiPicker(
                                isPresented: $showEmojiPicker,
                                selectedEmoji: $emojiPickerPicked
                            )
                            .onChange(of: emojiPickerPicked, { oldValue, newValue in
                                selectedEmoji = emojiPickerPicked
                                giveSuggestion = false
                            })
                            .onChange(of: eventName) { oldValue, newValue in
                                if editEvent_Cal == nil && giveSuggestion {
                                    debounceTask?.cancel()
                                    debounceTask = Task {
                                        let suggestion = await data.getSuggestion(newValue, top_n: 1)
                                        print(suggestion)
                                        
                                        await MainActor.run {
                                            selectedEmoji = suggestion
                                        }
                                    }
                                }
                            }
                    }
//                    .padding(.trailing)
                    Spacer()
                    
                    TextField("Event", text: $eventName)
                        .multilineTextAlignment(.leading)
                        .focused($eventNameTyping)
                        .underlineTextField(underline: .color3, focus: eventNameTyping, focusColor: Color(.color2))
                        .font(.system(size: 24))
                        .frame(width: 228, height: 80)
                }
                .padding(.bottom)
                
                //Schedule
                VStack{
                    Toggle(isOn: $isSchedule) {
                        Text("Schedule")
                            .font(.system(size: 20))
                            .bold()
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .color3))
                    .onChange(of: isSchedule) { oldValue, newValue in
                        if newValue == true{
                            isDuration = false
                        }
                    }
                    
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
                                .onAppear{
                                    //TODO: Init Start and end time
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
                    .onChange(of: isDuration) { oldValue, newValue in
                        if newValue == true{
                            isSchedule = false
                        }
                    }
                    
                    ZStack{
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.color1)
                            .frame(height: 60)
                            .shadow(radius: isDuration ? 1 : 0)
                        
                        if !useCustomDuration{
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
                                Text("More")
                                    .foregroundColor(.gray)
                                    .onTapGesture {
                                        withAnimation {
                                            showCustomDuration = true
                                            eventNameTyping = false
                                        }
                                    }
                            }
                            .padding()
                        }
                        else{
                            HStack{ 
                                ZStack{
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.white)
                                        .frame(height: 40)
                                    Text(Model.duration_to_string(Int32(customDuration)))
                                }
                                
                                Image(systemName: "x.square.fill")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 35, height: 40)
                                    .cornerRadius(7.5)
                                    .clipped()
                                    .foregroundStyle(.black, .error)
                                    .onTapGesture {
                                        withAnimation {
                                            useCustomDuration = false
                                        }
                                    }
                            }
                            .padding()
                        }
                    }
                    .opacity(isDuration ? 1 : 0.5)
                }
                
                Spacer()
                
                Button {
                    //Submit
                    if eventName.isEmpty{
                        eventNameTyping = true
                    }
                    else{
                        //Create the new event
                        var duration: Int = 0
                        
                        switch selectedIndex {
                        case 0: duration = 5
                        case 1: duration = 10
                        case 2: duration = 30
                        case 3: duration = 60
                        default: duration = -1
                        }
                        
                        if editEvent_Cal != nil{
                            editEvent_Cal?.edit(name: eventName, icon: selectedEmoji, startTime: isSchedule ? startTime.getHHMM() : nil, endTime: isSchedule ? endTime.getHHMM() : nil, duration: isDuration ? (useCustomDuration ? customDuration : duration) : -1)
                            
                            display = false
                        }
                        else{
                            //TODO: Logic for not creating is not done
                            let event: Event = Event.save(icon: selectedEmoji, name: eventName, startTime: isSchedule ? startTime.getHHMM() : nil, endTime: isSchedule ? endTime.getHHMM() : nil, duration: isDuration ? (useCustomDuration ? customDuration : duration) : -1)
                            let event_Cal = event.getEC()
                            
                            //if no Cal -> create Cal
                            let cal = Cal.get(date: date.getYYMMDD()) ?? Cal.new(date: date.getYYMMDD())
                            
                            //if no Section_Cal -> create empty Cal
                            let new_section_Cal: Section_Cal = section_Cal ?? Section_Cal.new()
                            
                            //put the event_Cal into the Section_Cal
                            new_section_Cal.add(event: event_Cal)
                            cal.add(new_section_Cal)
                            
                            print(cal.description)
                            
                            display = false
                        }
                    }
                } label: {
                    ZStack{
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.color3)
                            .frame(height: 40)
                            
                        Text(editEvent_Cal == nil ? "Add" : "Save")
                            .font(.system(size: 20))
                            .foregroundStyle(Color(.white))
                            .bold()
                        
                    }
                }
                .padding(.bottom)
                
                
            }
            .padding(.horizontal, K.horizontal_padding * 2)
            .padding(.top)
            .onAppear{
                eventNameTyping = true
                
                if let ec = editEvent_Cal{
                    eventName = ec.name ?? ""
                    selectedEmoji = ec.icon ?? "💡"
                    if ec.duration != -1{
                        isDuration = true
                        
                        switch ec.duration{
                        case 5: selectedIndex = 0
                        case 10: selectedIndex = 1
                        case 30: selectedIndex = 2
                        case 60: selectedIndex = 3
                        default:
                            useCustomDuration = true
                            customDuration = Int(ec.duration)
                        }
                    }
                    else if ec.startTime != nil{
                        isSchedule = true
                        startTime = Date.getDateFromHHMM(editEvent_Cal?.startTime ?? "00:00")
                        endTime = Date.getDateFromHHMM(editEvent_Cal?.endTime ?? "00:00")
                    }
                    else{
                        isDuration = false
                        isSchedule = false
                    }
                }
                
                
                            
            }
            .popup(isPresented: $showCustomDuration){
                DurationSelection(duration: $customDuration, successful: $useCustomDuration, isPresented: $showCustomDuration)
            } customize: {
                $0
                    .type(.floater())
                    .closeOnTap(false)
                    .closeOnTapOutside(true)
                    .backgroundColor(.black.opacity(0.5))
                    .dragToDismiss(false)
            }
            
        }
    }
}

#Preview {
    CreateEvent(display: .constant(false))
}
