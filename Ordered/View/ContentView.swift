//
//  ContentView.swift
//  Ordered
//
//  Created by Kai Hin Hung on 9/7/2024.
//

import SwiftUI
import CoreData
import PopupView

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
            .overlay(alignment: .bottom){// TabBar
                BottomBar(viewModel: viewModel)
            }
            .popup(isPresented: $viewModel.showEventDetail){
                EventDetailPopup(viewModel: viewModel)
            } customize: {
                $0
                    .type(.floater())
                    .closeOnTap(false)
                    .closeOnTapOutside(true)
                    .backgroundColor(.black.opacity(0.5))
                    
            }
        }
    }
}


#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
