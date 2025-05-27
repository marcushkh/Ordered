//
//  CreateEvent.swift
//  Ordered
//
//  Created by Kai Hin Hung on 18/10/2024.
//

import SwiftUI
import MCEmojiPicker
import CoreData
 
struct CreateEvent: View {
    @ObservedObject var viewModel: ContentViewModel
    
    @Namespace private var underlineNamespace
    @State var editEvent_Cal: Event_Cal? = nil
    @State var date: Date = Date()
    
    @State var giveSuggestion: Bool = true
    @State var selectedEmoji: String = "💡"
    @State var suggestedEmoji: String = ""
    
    @State var eventName: String = ""
    @FocusState var eventNameTyping
    
    @State var description: String = ""
    @FocusState var descriptionTyping
    @State var event: Event? = nil
    @State var isNewEvent: Bool = false
    
    @State var isFinished: Bool = false
    @State var isSchedule: Bool = false
    @State private var startTime = Date()
    @State private var endTime: Date = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    
    @State var isDuration: Bool = false
    
    @State private var selectedIndex: Int = 0
    private let durationOptions = ["5m", "10m", "30m", "1h"]
    
    @State var showCustomDuration: Bool = false
    @State var useCustomDuration: Bool = false
    @State private var customDuration: Int = 90
    
    @Binding var display: Bool
    @Environment(\.colorScheme) var colorScheme
    
    @State private var isInitializing = true
    
    let data = DataLoader()
    
    var body: some View {
        Background(color: .cBackground, allFocusStates: [$eventNameTyping, $descriptionTyping]){
            VStack{
                if !isNewEvent && event == nil{ //Give suggestion to use previous events
                    EventAndEmoji(eventName: $eventName, selectedEmoji: $selectedEmoji, eventNameTyping: $eventNameTyping, giveSuggestion: $giveSuggestion){
                        ZStack{
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.color1))
                                .frame(width: 60, height: 60)
                            
                            Text(selectedEmoji)
                                .font(.custom("", size: 50))
                                .shadow(radius: K.medium_size)
                                
                        }
                    } eventNameView: {
                        ZStack{
                            TextField("Event", text: $eventName)
                                .multilineTextAlignment(.leading)
                                .focused($eventNameTyping)
                                .underlineTextField(underline: .color3, focus: eventNameTyping, focusColor: Color(.color2))
                                .font(.system(size: 24))
                                .frame(width: 228, height: 80)
                        }
                    }
                    .padding(.bottom)
                    
                    
                    EventList(viewModel: viewModel, eventName: $eventName, selectedEvent: $event, toggleHeartSelectEvent: false)
                    
                    Spacer()
                    
                    newEventButton
                }
                else{
                    descriptionTextField
                    
                    if editEvent_Cal?.aStartTime != nil{ //Already started
                        aStartEndTimeSelection
                    }
                    if editEvent_Cal?.aStartTime == nil || !isFinished{
                        typeSelection
                    }
                    
                    Spacer()
                    
                    submitButton
                }
                
            }
            .onChange(of: event) { oldValue, newValue in
                if oldValue == nil{
                    isInitializing = false
                }
                if !isInitializing{
                    initEvent(newValue: newValue)
                }
                isInitializing = false
            }
            .padding(.horizontal, K.horizontal_padding * 2)
            .padding(.top)
            .onAppear{
                initialize()
            }
            .popup(isPresented: $showCustomDuration){
                DurationSelection(duration: $customDuration, successful: $useCustomDuration, isPresented: $showCustomDuration)
            } customize: {
                $0
                    .type(.floater())
                    .closeOnTap(false)
                    .closeOnTapOutside(true)
                    .backgroundColor(.cPrimary.opacity(0.2))
                    .dragToDismiss(false)
            }
        }
    }
    
    func initialize(changeToNotFinished: Bool = false){
        print("initialize")
        eventNameTyping = true
        descriptionTyping = true
        
        if let ec = editEvent_Cal{
            event = ec.parent
            
            eventName = event?.name ?? ""
            selectedEmoji = event?.icon ?? "💡"
            description = ec.detail ?? ""
            
            if ec.aStartTime != nil && !changeToNotFinished{
                isFinished = true
                startTime = Date.getDateFromHHMM(editEvent_Cal?.aStartTime ?? "00:00:00")
                if ec.aEndTime != nil{
                    endTime = Date.getDateFromHHMM(editEvent_Cal?.aEndTime ?? "00:00:00")
                }
            }
            else if ec.duration != -1{
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
                startTime = Date.getDateFromHHMM(editEvent_Cal?.startTime ?? "00:00:00")
                endTime = Date.getDateFromHHMM(editEvent_Cal?.endTime ?? "00:00:00")
            }
            else{
                isDuration = false
                isSchedule = false
            }
        }
        
        
    }
    
    func initEvent(newValue: Event?){
        
        withAnimation {
            print("INIT is used")
            selectedEmoji = newValue?.icon ?? "💡"
            eventName = newValue?.name ?? ""
            
            if newValue != nil{
                giveSuggestion = false
            }
            
            if newValue?.startTime != nil && newValue?.endTime != nil{
                isSchedule = true
                startTime = Date.getDateFromHHMM(newValue?.startTime! ?? "00:00:00")
                endTime = Date.getDateFromHHMM(newValue?.endTime! ?? "00:00:00")
            }
            else if newValue?.duration != -1 && newValue?.duration != nil{
                isDuration = true
                
                switch newValue?.duration{
                case 5: selectedIndex = 0
                case 10: selectedIndex = 1
                case 30: selectedIndex = 2
                case 60: selectedIndex = 3
                default:
                    useCustomDuration = true
                    customDuration = Int(newValue?.duration ?? 90)
                }
            }
            if isFinished{
                startTime = Date.getDateFromHHMM(editEvent_Cal?.aStartTime ?? "00:00:00")
                if editEvent_Cal?.aEndTime != nil{
                    endTime = Date.getDateFromHHMM(editEvent_Cal?.aEndTime ?? "00:00:00")
                }
            }
        }
    }
    
    func initEvent(newValue: Event_Cal?){
        
        withAnimation {
            print("INIT is used")
            selectedEmoji = newValue?.parent?.icon ?? "💡"
            eventName = newValue?.parent?.name ?? ""
            
            if newValue?.startTime != nil && newValue?.endTime != nil{
                isSchedule = true
                startTime = Date.getDateFromHHMM(newValue?.startTime! ?? "00:00:00")
                endTime = Date.getDateFromHHMM(newValue?.endTime! ?? "00:00:00")
            }
            else if newValue?.duration != -1 && newValue?.duration != nil{
                isDuration = true
                
                switch newValue?.duration{
                case 5: selectedIndex = 0
                case 10: selectedIndex = 1
                case 30: selectedIndex = 2
                case 60: selectedIndex = 3
                default:
                    useCustomDuration = true
                    customDuration = Int(newValue?.duration ?? 90)
                }
            }
            if isFinished{
                startTime = Date.getDateFromHHMM(editEvent_Cal?.aStartTime ?? "00:00:00")
                if editEvent_Cal?.aEndTime != nil{
                    endTime = Date.getDateFromHHMM(editEvent_Cal?.aEndTime ?? "00:00:00")
                }
            }
        }
    }
    
    var descriptionTextField: some View{
        HStack{
            ZStack{
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.color1))
                    .frame(width: 60, height: 60)
                
                Text(selectedEmoji)
                    .font(.custom("", size: 50))
                    .shadow(radius: K.medium_size)
                    .onTapGesture {
                        isSchedule = false
                        isDuration = false
                        isNewEvent = false
                        event = nil
                    }
            }
            Spacer()
            
            VStack(alignment: .leading, spacing: 8){
                Text(eventName + ":")
                    .multilineTextAlignment(.leading)
                    .font(.system(size: 24))
                
                TextField("Description (Optional)", text: $description)
                    .multilineTextAlignment(.leading)
                    .focused($descriptionTyping)
                    .underlineTextField(underline: .color3, focus: descriptionTyping, focusColor: Color(.color2))
                    .font(.system(size: 16))
                    .frame(width: 228, height: 16)
            }
        }
        .padding(.vertical)
    }
    
    
    
    var typeSelection: some View{
        VStack{
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
                                            .fill(.cBackground)
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
                                    .fill(.cBackground)
                                    .frame(height: 40)
                                Text(Model.duration_to_string(min: Int32(customDuration)))
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
        }
    }
    
    var aStartEndTimeSelection: some View{
        VStack{
            Toggle(isOn: $isFinished) {
                Text(editEvent_Cal?.aEndTime == nil ? "On Going: " : "Finished: ")
                        .font(.system(size: 20))
                        .bold()
                }
                .toggleStyle(SwitchToggleStyle(tint: .color3))
                .onChange(of: isFinished) { oldValue, newValue in
                    if newValue == true{
                        isSchedule = false
                        isDuration = false
                        startTime = Date.getDateFromHHMM(editEvent_Cal?.aStartTime ?? startTime.getHHMM())
                        endTime = Date.getDateFromHHMM(editEvent_Cal?.aEndTime ?? endTime.getHHMM())
                    }
                    else{
                        initEvent(newValue: editEvent_Cal)
                    }
                }
            
            if isFinished{
                ZStack{
                    if editEvent_Cal?.aStartTime != editEvent_Cal?.aEndTime{
                        
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.color1)
                        .shadow(radius: isFinished ? 1 : 0)
                        .frame(height: editEvent_Cal?.aEndTime == nil ? 50 : 100)
                    
                        VStack{
                            DatePicker("Start Time: ", selection: $startTime, displayedComponents: .hourAndMinute)
                                .padding(.horizontal)
                                .tint(.color4)
                                .onChange(of: startTime) { oldValue, newValue in
                                    if endTime <= newValue {
                                        endTime = startTime
                                    }
                                }
                            
                            if editEvent_Cal?.aEndTime != nil{
                                DatePicker("End Time: ", selection: $endTime, displayedComponents: .hourAndMinute)
                                    .padding(.horizontal)
                                    .tint(.color4)
                                    .onChange(of: endTime) { oldValue, newValue in
                                        if newValue <= startTime {
                                            startTime = endTime
                                        }
                                    }
                            }
                        }
                    }
                    else{//Tick event
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.color1)
                            .shadow(radius: isFinished ? 1 : 0)
                            .frame(height: 50)
                        
                        DatePicker("Tick Time: ", selection: $startTime, displayedComponents: .hourAndMinute)
                            .padding(.horizontal)
                            .tint(.color4)
                            .onChange(of: startTime) { oldValue, newValue in
                                endTime = startTime
                            }
                    }
                    
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    var newEventButton: some View{
        Button{
            if eventName.isEmpty{
                eventNameTyping = true
            }
            else{
                if Event.count() >= 10 && !viewModel.isSubscriptionActive{
                    viewModel.showCreateEvent = false
                    viewModel.isShowPaywall = true
                }
                else{
                    withAnimation {
                        isNewEvent = true
                        descriptionTyping = true
                    }
                }
            }
        } label: {
            ZStack{
                RoundedRectangle(cornerRadius: 20)
                    .fill(.color3)
                    .frame(height: 40)
                
                Text("New Event")
                    .font(.system(size: 20))
                    .foregroundStyle(Color(.white))
                    .bold()
            }
        }
        .padding(.bottom)
    }
    
    var submitButton: some View{
        Button {
            submit()
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
    
    func submit(){
        //Submit
        //Create the new event
        var duration: Int = 0
        
        switch selectedIndex {
        case 0: duration = 5
        case 1: duration = 10
        case 2: duration = 30
        case 3: duration = 60
        default: duration = -1
        }
        
        if editEvent_Cal == nil{ //Create new event
            // Emoji Recommender Learning
            if (event == nil && selectedEmoji != suggestedEmoji){
                data.learn(emoji: selectedEmoji, description: eventName)
            }
            
            //TODO: Logic for not creating is not done
            let event: Event = self.event ?? Event.save(icon: selectedEmoji, name: eventName, startTime: isSchedule ? startTime.getHHMM() : nil, endTime: isSchedule ? endTime.getHHMM() : nil, duration: isDuration ? (useCustomDuration ? customDuration : duration) : -1)
            
            if isSchedule || isDuration {
                Event.save(startTime: isSchedule ? startTime.getHHMM() : nil, endTime: isSchedule ? endTime.getHHMM() : nil, duration: isDuration ? (useCustomDuration ? customDuration : duration) : -1, event: event)
            }
            
            let event_Cal = event.getEC()
            event_Cal.detail = description
            
            let new_section_Cal: Section_Cal = viewModel.createEvent_Section_Cal ?? Section_Cal.new()
            new_section_Cal.add(event: event_Cal)
            
            //if no Cal -> create Cal
            let cal = Cal.get(date: date.getYYMMDD()) ?? Cal.new(date: date.getYYMMDD())
            
            cal.add(new_section_Cal)
            cal.sort()
            

            if viewModel.currentTab == .plan{
                viewModel.highlightedEC = event_Cal
            }
            display = false
        }
        
        if let ec = editEvent_Cal{ //Edit event
            if ec.aStartTime == nil{ // Normal Edit event
                if isSchedule || isDuration{
                    event = Event.save(startTime: isSchedule ? startTime.getHHMM() : nil, endTime: isSchedule ? endTime.getHHMM() : nil, duration: isDuration ? (useCustomDuration ? customDuration : duration) : -1, event: event)
                }
                
                ec.edit(detail: description, startTime: isSchedule ? startTime.getHHMM() : nil, endTime: isSchedule ? endTime.getHHMM() : nil, duration: isDuration ? (useCustomDuration ? customDuration : duration) : -1, aStartTime: nil, aEndTime: nil, parent: event)
            }
            else{ // Started
                
                if ec.aEndTime == nil{ // On Going
                    if EventActionHandler.shared.currentECID == ec.objectID.uriRepresentation().absoluteString {
                        if !isFinished{
                            EventActionHandler.shared.reset()
                        }
                        else{
                            let oStartTime = Date.getDateFromHHMM(ec.aStartTime!)
                            var changeInMin = Calendar.current.dateComponents([.minute], from: startTime, to: oStartTime).minute!
                            if changeInMin > 720{
                                changeInMin -= 24*60
                            }
                            if changeInMin < -720{
                                changeInMin += 24*60
                            }
                            EventActionHandler.shared.AddCurrentTimePassed(min: changeInMin)
                        }
                    }
                    
                    //Edit time
                    ec.edit(detail: description, startTime: ec.startTime, endTime: ec.endTime, duration: Int(ec.duration), aStartTime: isFinished ? startTime.getHHMM() : nil, aEndTime: nil, parent: event)
                }
                else{ //Finished
                    //edit duration
                    var d = Int(ec.durationFinished)
                    let pStartTime = Date.getDateFromHHMM(ec.aStartTime!)
                    let pEndTime = Date.getDateFromHHMM(ec.aEndTime!)
                    
                    let changeInMin = Calendar.current.dateComponents([.minute], from: startTime, to: endTime).minute! - Calendar.current.dateComponents([.minute], from: pStartTime, to: pEndTime).minute!
                    
                    d += changeInMin
                    if d < 0{ d = 0 }
                    
                    ec.edit(detail: description, startTime: ec.startTime, endTime: ec.endTime, duration: Int(ec.duration), aStartTime: isFinished ? startTime.getHHMM() : nil, aEndTime: isFinished ? endTime.getHHMM() : nil, durationFinished: isFinished ? d : 0, parent: event)
                }
                
            }
            if viewModel.currentTab == .plan {
                viewModel.highlightedEC = ec
                viewModel.highlightedSC = nil
            }
            display = false
        }
    }
}
