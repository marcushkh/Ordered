//
//  EventDetailPopup.swift
//  Ordered
//
//  Created by Kai Hin Hung on 22/8/2024.
//

import SwiftUI

struct EventDetailPopup: View {
    @ObservedObject var viewModel: ContentViewModel
    @State var showAlert: Bool = false
    
    var body: some View {
        VStack(spacing: 12){
            HStack{
                ECInfo(ec: viewModel.eventDetail!, highlightedEC: $viewModel.highlightedEC)
                Spacer()
            }
            .overlay(alignment: .topTrailing){
                Image(systemName: "x.circle.fill")
                    .foregroundStyle(.cBackground, .secondary)
                    .font(.title2)
                    .onTapGesture {
                        viewModel.showEventDetail = false
                    }
            }
            
            Divider()
                .background(Color.blue)
                .frame(height: 2)
            
            HStack{
                Button(action: {
                    showAlert = true
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
                    viewModel.editEvent_Cal = viewModel.eventDetail
                    viewModel.createEvent_Section_Cal = nil
                    viewModel.showEventDetail = false
                    viewModel.showCreateEvent = true
                }) {
                    VStack{
                        Image(systemName: "pencil.line")
                        Text("Edit")
                    }
                    .frame(width: 90, height: 50)
                    .background(.color1)
                    .cornerRadius(10)
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(  title: Text("Delete Event"),
                        message: Text("Are you sure you want to delete this item?"),
                        primaryButton: .destructive(Text("Delete")) {
                            viewModel.eventDetail?.delete()
                            viewModel.showEventDetail = false
                        },
                        secondaryButton: .cancel())
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
        .background(Color.cBackground.cornerRadius(30))
        .padding(.horizontal, K.horizontal_padding)
        .onDisappear{
            print("Event Detail is nil now")
            viewModel.eventDetail = nil
        }
    }
}

struct EventDetailPopup_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = ContentViewModel()
        viewModel.eventDetail = Sample.sampleEC
        
        return EventDetailPopup(viewModel: viewModel)
    }
}
