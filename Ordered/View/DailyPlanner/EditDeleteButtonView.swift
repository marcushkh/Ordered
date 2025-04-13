//
//  EditDeleteButtonView.swift
//  Ordered
//
//  Created by Kai Hin Hung on 20/2/2025.
//

import SwiftUI

struct EditDeleteButtonView: View{
    @ObservedObject var viewModel: ContentViewModel
    @ObservedObject var ec: Event_Cal
    @Binding var activeAlert: ActiveAlert?
    
    var body: some View{
        HStack{
            var colorOfCircle: Color {
                if ec.aEndTime != nil{
                    return .success
                }
                if ec.aStartTime != nil{
                    return .info
                }
                return .color1
            }
            Button{
                viewModel.editEvent_Cal = ec
                viewModel.createEvent_Section_Cal = nil
                viewModel.showCreateEvent = true
            } label: {
                ZStack{
                    Circle()
                        .fill(colorOfCircle)
                        .frame(height: K.medium_size)
                    
                    Image(systemName: "pencil.line")
                        .foregroundStyle(.cPrimary)
                }
            }

            Button{
                activeAlert = .deleteEvent(ec)
            } label: {
                ZStack{
                    Circle()
                        .fill(.error)
                        .frame(height: K.medium_size)
                    
                    Image(systemName: "trash")
                        .foregroundStyle(.cPrimary)
                }
            }
            
        }
        
    }
}

