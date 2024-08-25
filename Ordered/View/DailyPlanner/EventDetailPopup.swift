//
//  EventDetailPopup.swift
//  Ordered
//
//  Created by Kai Hin Hung on 22/8/2024.
//

import SwiftUI

struct EventDetailPopup: View {
    @StateObject var viewModel: ContentViewModel
    
    var body: some View {
        VStack(spacing: 12){
            HStack{
                EventInfo(ec: viewModel.eventDetail)
                Spacer()
            }
            .overlay(alignment: .topTrailing){
                Image(systemName: "x.circle.fill")
                    .foregroundStyle(.cBackground, .secondary)
                    .font(.title3)
                    .onTapGesture {
                        viewModel.showEventDetail = false
                    }
            }
            
            Divider()
                .background(Color.blue)
                .frame(height: 2)
            
            HStack{
                Button(action: {
                    // Action for Delete
                }) {
                    VStack{
                        Image(systemName: "trash")
                        Text("Delete")
                    }
                    .frame(width: 90, height: 50)
                    .background(.color1)
                    .cornerRadius(10)
                }
                
                Spacer()
                
                Button(action: {
                    // Action for Delete
                }) {
                    VStack{
                        Image(systemName: "trash")
                        Text("Delete")
                    }
                    .frame(width: 90, height: 50)
                    .background(.color1)
                    .cornerRadius(10)
                }
                
                Spacer()
                
                Button(action: {
                    // Action for Delete
                }) {
                    VStack{
                        Image(systemName: "square.and.pencil")
                        Text("Edit")
                    }
                    .frame(width: 90, height: 50)
                    .background(.color1)
                    .cornerRadius(10)
                }
            }
            
            Button(action: {
                
            }, label: {
                ZStack{
                    Rectangle()
                        .fill(.color1)
                        .frame(height: 40)
                        .cornerRadius(10)
                    
                    HStack{
                        Image(systemName: "play.circle")
                        Text("Start Now")
                    }
                }
            })
        }
        .foregroundStyle(.cPrimary)
        .padding(.horizontal, K.horizontal_padding)
        .padding(.vertical, K.large_size)
        .background(Color.white.cornerRadius(30))
        .padding(.horizontal, K.horizontal_padding)
    }
}

struct EventDetailPopup_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ContentViewModel()
        viewModel.eventDetail = Sample.sampleEC
        
        return EventDetailPopup(viewModel: viewModel)
    }
}
