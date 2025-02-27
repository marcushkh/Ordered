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
    
    @State private var selectedSegment = "Week"
    let segments = ["Week", "Month", "Year"]
    
    @State var currentDate = Date.now
    @State private var selectedEventID: ObjectIdentifier? = nil
    
    @FetchRequest(
        entity: Event.entity(),
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Event.isFavourite, ascending: false),
            NSSortDescriptor(keyPath: \Event.order, ascending: true)
        ]
    ) private var allEvents: FetchedResults<Event>
    
    var body: some View {
        GeometryReader{ geo in
            let h = geo.size.height
            let w = geo.size.width
            
            VStack(spacing: 8){
                Picker("Select Timeframe", selection: $selectedSegment) {
                    ForEach(segments, id: \.self) { segment in
                        Text(segment).tag(segment)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, w*0.075)
                .disabled(true)
                
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
                    .scrollTargetLayout()
                    .scrollTargetBehavior(.viewAligned)
                    .scrollPosition(id: $selectedEventID, anchor: .leading)
                }
                .onChange(of: viewModel.selectedEvent) { _, _ in
                    withAnimation {
                        selectedEventID = viewModel.selectedEvent?.id
                    }
                }
            }
        }
        .frame(height: 250)
        .padding(.bottom, 2)
    }
}

