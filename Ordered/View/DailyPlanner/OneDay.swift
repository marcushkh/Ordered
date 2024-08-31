//
//  MainList.swift
//  Ordered
//
//  Created by Kai Hin Hung on 1/8/2024.
//

import SwiftUI

struct OneDay: View {
    
    var date: Date
    var pos: ViewPosition
    @StateObject var viewModel: ContentViewModel
    @StateObject var dayPlannerVM: DayPlannerViewModel
    private var calendarFetchRequest: FetchRequest<Cal>
    
    init(date: Date, pos: ViewPosition, viewModel: ContentViewModel, dayPlannerVM: DayPlannerViewModel) {
        self.date = date
        self.calendarFetchRequest = FetchRequest(
            entity: Cal.entity(),
            sortDescriptors: [],
            predicate: NSPredicate(format: "date == %@", date as NSDate)
        )
        self.pos = pos
        _viewModel = StateObject(wrappedValue: viewModel)
        _dayPlannerVM = StateObject(wrappedValue: dayPlannerVM)
        
    }
    
    var toDoForDate: FetchedResults<Cal> {
        calendarFetchRequest.wrappedValue
    }
    
    var body: some View {
        
        if toDoForDate.first != nil{
            ScrollView{
                ForEach(toDoForDate.first?.section_cals?.array as! [Section_Cal], id: \.self){ sc in
                    
                    VStack{
                        //Section Header
                        HStack(alignment: .bottom){
                            
                            Text(sc.name ?? "")
                                .font(.title3)
                                .bold()
                            
                            Spacer()
                            
                            Circle()
                                .fill(Color(hex: sc.color))
                                .frame(width: K.medium_size, height: K.medium_size)
                                .overlay{
                                    ColorPicker("", selection: .constant(Color(hex: sc.color))).labelsHidden().opacity(0.015)
                                }
                            
                        }
                        
                        Divider()
                            .background(Color.blue)
                            .frame(height: 2)
                            .padding(.top, -8)
                        
                        //Events
                        ForEach(sc.event_cals?.array as! [Event_Cal], id: \.self){ ec in
                            HStack{
                                EventInfo(ec: ec)
                                
                                Spacer()
                                
                                ZStack{
                                    Circle()
                                        .fill(.color1)
                                        .frame(height: K.medium_size)
                                    
                                    Image(systemName: ec.duration == -1 ? "checkmark" : "play")
                                }
                            }
                            .onTapGesture {
                                viewModel.showEventDetail = true
                                viewModel.eventDetail = ec
                            }
                        }
                    }
                    .padding(.vertical)
                    .padding(.horizontal, K.horizontal_padding)
                }
            }
            .onChange(of: date) {
                if pos == .centerView{
                    dayPlannerVM.setCurrentDate(to: date)
                }
            }
        }
        else{
            ZStack{
                Rectangle()
                    .fill(.color1)
                Text("Sorry this day is too far for adding")
            }
            .onChange(of: date) {
                if pos == .centerView{
                    dayPlannerVM.setCurrentDate(to: date)
                }
            }
        }
    }
}

#Preview {
    OneDay(date: MyCalendar.getDate(from: "20240826"), pos: .centerView, viewModel: ContentViewModel(), dayPlannerVM: DayPlannerViewModel())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
