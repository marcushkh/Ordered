//
//  Stat.swift
//  Ordered
//
//  Created by Kai Hin Hung on 13/2/2025.
//
import SwiftUI
import Charts
import CoreData

struct StatTopBar: View {
    @ObservedObject var viewModel: ContentViewModel
    @ObservedObject var dayPlannerVM: DayPlannerViewModel
    
    @State var currentDate = Date.now
    @State private var selectedEventID: ObjectIdentifier? = nil
    
    @Environment(\.colorScheme) var colorScheme
    
    @FetchRequest(
        entity: Event.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Event.isFavourite, ascending: false),
            NSSortDescriptor(keyPath: \Event.order, ascending: true)
        ],
        predicate: NSPredicate(format: "isActive == true")  
    ) private var allEvents: FetchedResults<Event>
    
    var body: some View {
        GeometryReader{ geo in
            let h = geo.size.height
            let w = geo.size.width
            
            VStack(spacing: 8){
                ZStack{
                    RoundedRectangle(cornerRadius: 15)
                        .fill(.color5)
                        .frame(height: 40)
                    
                    HStack{
                        var dateString: String{
                            let formatter = DateFormatter()
                            formatter.dateFormat = "d MMM"
                            
                            if currentDate.getYYMMDD() == Date.now.getYYMMDD(){
                                return "This Week"
                            }
                            else if currentDate.getYYMMDD() == Calendar.current.date(byAdding: .day, value: -7, to: Date.now)?.getYYMMDD(){
                                return "Last Week"
                            }
                            else{
                                return formatter.string(from: dayPlannerVM.datesInAWeek(from: dayPlannerVM.startDateOfWeek(from: currentDate))[0]) + " - " + formatter.string(from: dayPlannerVM.datesInAWeek(from: dayPlannerVM.startDateOfWeek(from: currentDate))[6])
                            }
                        }
                        Text(dateString)
                        
                        Spacer()
                        
                        Button {
                            withAnimation {
                                HapticFeedback.light()
                                currentDate = Calendar.current.date(byAdding: .day, value: -7, to: currentDate) ?? currentDate
                            }
                        } label: {
                            Image(systemName: "play.fill")
                                .rotationEffect(.degrees(180))
                                .font(.system(size: 12))
                                .foregroundColor(.cPrimary)
                                .padding(8)
                                .background(colorScheme == .dark ? .color3 : .color2)
                                .clipShape(Circle())
                        }
                        
                        Button {
                            withAnimation {
                                HapticFeedback.light()
                                var nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: currentDate) ?? currentDate
                                currentDate = nextWeek > Date.now ? Date.now : nextWeek
                            }
                        } label: {
                            Image(systemName: "play.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.cPrimary)
                                .padding(8)
                                .background(colorScheme == .dark ? .color3 : .color2)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.horizontal, w*0.075)
                
                ScrollViewReader{ proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 20) {
                            ForEach(allEvents){event in
                                ZStack{
                                    RoundedRectangle(cornerRadius: 24)
                                        .fill(.cBackground)
                                    
                                    VStack(spacing: 0){
                                        HStack{
                                            Circle()
                                                .fill(.color2)
                                                .frame(width: 48, height: 48)
                                                .padding()
                                                .overlay{
                                                    Text(event.icon ?? "💡")
                                                        .font(.system(size: 40))
                                                }
                                            
                                            Text(event.name ?? "")
                                                .font(.system(size: 24))
                                            Spacer()
                                        }
                                        
                                        Chart {
                                            ForEach(dayPlannerVM.datesInAWeek(from: dayPlannerVM.startDateOfWeek(from: currentDate)), id: \.self){ date in
                                                BarMark(
                                                    x: .value("Day Representation", date.weekDayAbbrev()),
                                                    y: .value("Total Count or Minute", (event.duration != -1 || event.startTime != nil) ? event.totalTime(on: date) : event.finished(on: date))
                                                )
                                            }
                                        }
                                        .chartYAxis {
                                            if event.duration != -1 || event.startTime != nil{
                                                AxisMarks(values: .stride(by: 60)) {
                                                    let min = $0.as(Int.self)!
                                                    AxisValueLabel {
                                                        Text("\(min/60)h")
                                                    }
                                                }
                                            }
                                            else{
                                                AxisMarks() {
                                                    let times = $0.as(Int.self)!
                                                    AxisValueLabel {
                                                        Text("\(times)")
                                                    }
                                                }
                                            }
                                        }
                                        .padding()
                                        .foregroundStyle(.color4)
                                    }
                                }
                                .frame(width: w * 0.85, height: 200)
                                .id(event.id)
                            }
                        }
                        .padding(.horizontal, w * 0.075)
                    }
                    .scrollIndicators(.hidden)
                    .scrollTargetLayout()
                    .scrollTargetBehavior(.viewAligned)
                    .scrollPosition(id: $selectedEventID, anchor: .leading)
                }
                .onChange(of: viewModel.selectedEvent) { _, _ in
                    withAnimation {
                        HapticFeedback.light()
                        selectedEventID = viewModel.selectedEvent?.id
                    }
                }
            }
        }
        .frame(height: 250)
        .padding(.bottom, 2)
    }
}

