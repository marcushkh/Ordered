//
//  ActionButtonView.swift
//  Ordered
//
//  Created by Kai Hin Hung on 25/1/2025.
//
import SwiftUI

struct ActionButtonView: View{
    
    @ObservedObject var viewModel: ContentViewModel
    @ObservedObject var sc: Section_Cal
    @ObservedObject var ec: Event_Cal
    @ObservedObject var actionHandler = EventActionHandler.shared
    
    var body: some View{
        var colorOfBase: Color{
            if ec.aEndTime != nil{
                return Color(.success)
            }
            else if ec.aStartTime != nil{
                return Color(.info)
            }
            else{
                return Color(.color1)
            }
        }
        
        if ec.duration == -1 && ec.startTime == nil {
            // Tick events
            ZStack{
                Circle()
                    .fill(colorOfBase)
                    .frame(height: K.medium_size)
                    .onChange(of: viewModel.refresh) { _, _ in
                    }
                
                Image(systemName: "checkmark")
            }
            .onTapGesture {
                if ec.aEndTime == nil{
                    withAnimation {
                        ec.aStartTime = Date.now.getHHMM()
                        ec.aEndTime = Date.now.getHHMM()
                        viewModel.refresh.toggle()
                    }
                }
            }
            
        }
        else{
            // Scheduled events and Duration events
            if actionHandler.isCurrentEC(ec: ec){
                //Current EC is in action
                ZStack{
                    Circle()
                        .fill(colorOfBase)
                        .frame(height: K.medium_size)
                        .onChange(of: viewModel.refresh) { _, _ in
                            
                        }
                    Image(systemName: "square")
                        .onTapGesture {
                            withAnimation {
                                actionHandler.end(ec: ec)
                                viewModel.refresh.toggle()
                            }
                        }
                }
                
                if actionHandler.startTime != nil{
                    //It is now running
                    ZStack{
                        Circle()
                            .fill(colorOfBase)
                            .frame(height: K.medium_size)
                            .onChange(of: viewModel.refresh) { _, _ in
                            }
                        Image(systemName: "pause")
                            .onTapGesture {
                                withAnimation {
                                    actionHandler.pause(ec: ec)
                                    viewModel.refresh.toggle()
                                }
                            }
                    }
                }
                else{
                    //It is paused now
                    ZStack{
                        Circle()
                            .fill(colorOfBase)
                            .frame(height: K.medium_size)
                            .onChange(of: viewModel.refresh) { _, _ in
                                //                            print("viewModel.refreshed")
                            }
                        if ec.aEndTime == nil{
                            Image(systemName: "play")
                                .onTapGesture {
                                    withAnimation {
                                        actionHandler.resume(ec: ec)
                                        viewModel.refresh.toggle()
                                    }
                                }
                        }
                        else{
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            else{
                // Not current EC
                ZStack{
                    Circle()
                        .fill(colorOfBase)
                        .frame(height: K.medium_size)
                        .onChange(of: viewModel.refresh) { _, _ in
                            //                        print("viewModel.refreshed")
                        }
                    if ec.aEndTime == nil{
                        Image(systemName: "play")
                            .onTapGesture {
                                withAnimation {
                                    // If self already have aEndTime => Add a completely new Event_Cal and start now
                                    if ec.aEndTime != nil{ //Create new EC
                                        if let newEC: Event_Cal = ec.parent?.getEC() as? Event_Cal{
                                            print("Successful")
                                            //Put in SC
                                            sc.insert(newEC, after: ec)
                                            
                                            //Start EC
                                            actionHandler.start(ec: newEC)
                                            viewModel.refresh.toggle()
                                        }
                                        
                                    }
                                    else{
                                        //If dont have aEndTime => just start
                                        actionHandler.start(ec: ec)
                                        viewModel.refresh.toggle()
                                    }
                                }
                            }
                    }
                    else{
                        Image(systemName: "checkmark")
                    }
                }
                
                
            }
        }
    }
}
