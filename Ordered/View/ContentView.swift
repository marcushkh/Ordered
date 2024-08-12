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
    
    var body: some View {
        GeometryReader{ geo in
            let w = geo.size.width
            let h = geo.size.height
            
            VStack(spacing: 0){
                //Top Bar
                TopBar(viewModel: viewModel)
                
                //Records
                ScrollView {
                    MainList()
                }
            }
            .frame(width: w, height: h)
            // TabBar
            .overlay(alignment: .bottom){
                BottomBar(viewModel: viewModel)
            }
        }
    }
}


#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
