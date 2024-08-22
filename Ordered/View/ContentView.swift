//
//  ContentView.swift
//  Ordered
//
//  Created by Kai Hin Hung on 9/7/2024.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject var viewModel = ContentViewModel()
    @StateObject var dayPlannerVM = DayPlannerViewModel()
    
    var body: some View {
        GeometryReader{ geo in
            let w = geo.size.width
            let h = geo.size.height
            
            VStack(spacing: 0){
                //Top Bar
                TopBar(viewModel: viewModel, dayPlannerVM: dayPlannerVM)
                
                //Records
                MainList(viewModel: viewModel, dayPlannerVM: dayPlannerVM)
                    .ignoresSafeArea()
                
            }
            .frame(width: w, height: h)
            // TabBar
            .overlay(alignment: .bottom){
                BottomBar(viewModel: viewModel)
            }
            //Pop up detail
            .overlay{
                if viewModel.showEventDetail{
                    ZStack(alignment: .bottom){
                        Color(.black)
                            .opacity(0.3)
                            .ignoresSafeArea()
                            .onTapGesture {
                                viewModel.showEventDetail = false
                            }
                        
                        Text("HIHIHI")
                    }
                }
            }
        }
    }
}


#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
