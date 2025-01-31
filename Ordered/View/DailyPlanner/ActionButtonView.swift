//
//  ActionButtonView.swift
//  Ordered
//
//  Created by Kai Hin Hung on 25/1/2025.
//
import SwiftUI

struct ActionButtonView: View{
    
    @ObservedObject var viewModel: ContentViewModel
    @ObservedObject var ec: Event_Cal
    @ObservedObject var actionHandler = EventActionHandler.shared
    
    var body: some View{
        // Scheduled events
        if actionHandler.isCurrentEC(ec: ec){
            ZStack{
                Circle()
                    .fill(.color1)
                    .frame(height: K.medium_size)
                    .onChange(of: viewModel.refresh) { _, _ in
                        print("viewModel.refreshed")
                    }
                Image(systemName: "square")
                    .onTapGesture {
                        withAnimation {
                            actionHandler.end(ec: ec)
                        }
                    }
            }
            
            //Current EC is in action
            if actionHandler.startTime != nil{
                //It is now running
                ZStack{
                    Circle()
                        .fill(.color1)
                        .frame(height: K.medium_size)
                        .onChange(of: viewModel.refresh) { _, _ in
                            print("viewModel.refreshed")
                        }
                    Image(systemName: "pause")
                        .onTapGesture {
                            withAnimation {
                                actionHandler.pause(ec: ec)
                            }
                        }
                }
            }
            else{
                //It is paused now
                ZStack{
                    Circle()
                        .fill(.color1)
                        .frame(height: K.medium_size)
                        .onChange(of: viewModel.refresh) { _, _ in
                            print("viewModel.refreshed")
                        }
                    Image(systemName: "play")
                        .onTapGesture {
                            withAnimation {
                                actionHandler.resume(ec: ec)
                            }
                        }
                }
            }
            
        }
        else{
            // Not current EC
            ZStack{
                Circle()
                    .fill(.color1)
                    .frame(height: K.medium_size)
                    .onChange(of: viewModel.refresh) { _, _ in
                        print("viewModel.refreshed")
                    }
                Image(systemName: "play")
                    .onTapGesture {
                        withAnimation {
                            actionHandler.start(ec: ec)
                        }
                    }
            }
        }
    }
}
