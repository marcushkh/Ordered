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
    @ObservedObject var viewModel: ContentViewModel
    @ObservedObject var dayPlannerVM: DayPlannerViewModel
    
    private var calendarFetchRequest: FetchRequest<Cal>
    
    //tobe deleted
    @State var refresh: Bool = false
    
    init(date: Date, pos: ViewPosition, viewModel: ContentViewModel, dayPlannerVM: DayPlannerViewModel) {
        self.date = date
        
        self.calendarFetchRequest = FetchRequest(
            entity: Cal.entity(),
            sortDescriptors: [],
            predicate: NSPredicate(format: "date == %@", date.getYYMMDD())
        )
        
        self.pos = pos
        _viewModel = ObservedObject(wrappedValue: viewModel)
        _dayPlannerVM = ObservedObject(wrappedValue: dayPlannerVM)
        
    }
    
    var toDoForDate: FetchedResults<Cal> {
        calendarFetchRequest.wrappedValue
    }
    
    var body: some View {
        ScrollView{
            if toDoForDate.first != nil{
                
                ForEach(toDoForDate.first?.section_cals?.array as! [Section_Cal], id: \.self){ sc in
                    
                    VStack{
                        //Section Header
                        HStack(alignment: .bottom){
                            
                            Text(sc.name ?? "")
                                .font(.title3)
                                .bold()
                            
                            Spacer()
                            
                            
                            ColorPicker("", selection: Binding(get: {
                                Color(hex: sc.color)
                            }, set: { c in
                                let color: String = c.toHex() ?? "000000"
                                sc.setColor(color)
                                refresh.toggle()
                            }))
                            .labelsHidden()
                            .overlay{
                                Circle()
                                    .fill(Color(hex: sc.color))
                                    .frame(width: K.medium_size, height: K.medium_size)
                            }
                            
                            
                        }
                        
                        Divider()
                            .background(Color.blue)
                            .frame(height: 2)
                            .padding(.top, -8)
                        
                        //Events
                        ForEach(sc.event_cals?.array as! [Event_Cal], id: \.self){ ec in
                            HStack{
                                ECInfo(ec: ec, refresh: refresh)
                                
                                Spacer()
                                
                                ZStack{
                                    Circle()
                                        .fill(.color1)
                                        .frame(height: K.medium_size)
                                        .onChange(of: refresh) { _, _ in
                                            print("Refreshed")
                                        }
                                    
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
            else{
                
                ZStack{
                    Rectangle()
                        .fill(.white)
                    VStack{
                        Image("NoEventIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 300)
                            .onTapGesture {
                                viewModel.showCreateEvent = true
                            }
                        
                        Text("Decorate Your Schedule")
                            .font(.title2)
                            .bold()
                        
                        Spacer()
                    }
                    
                }
                
                
            }
        }
        .onChange(of: date) {
            if pos == .centerView{
                dayPlannerVM.setCurrentDate(to: date)
            }
        }
        .onChange(of: refresh) { _, _ in
            print("Refreshed")
        }
    }
}

#Preview {
    OneDay(date: MyCalendar.getDate(from: "240826"), pos: .centerView, viewModel: ContentViewModel(), dayPlannerVM: DayPlannerViewModel())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
