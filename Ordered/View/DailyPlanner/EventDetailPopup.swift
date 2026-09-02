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

            if let category = viewModel.eventDetail?.parent?.activeCategories.first {
                HStack {
                    Text("\(category.icon ?? "🏷️") \(category.name ?? "Category")")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(hex: category.color).opacity(0.25), in: Capsule())
                    Spacer()
                }
            }
            
            Divider()
                .background(Color.color3)
                .frame(height: 16)
            
            HStack(spacing: 12){
                Button(action: {
                    showAlert = true
                }) {
                    VStack{
                        Image(systemName: "trash")
                        Text("Delete")
                    }
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(.color1)
                    .cornerRadius(10)
                }
                
                Button(action: {
                    withAnimation {
                        let ec = viewModel.eventDetail?.copyFunction()
                        if ec != nil && viewModel.eventDetail != nil{
                            viewModel.eventDetail?.section_cal?.insert(ec!, after: viewModel.eventDetail!)
                        }
                        viewModel.refresh.toggle()
                        viewModel.showEventDetail = false
                    }
                }) {
                    VStack{
                        ZStack(alignment: .bottomTrailing){
                            Image(systemName: "document.on.document")
                        }
                        Text("Duplicate")
                    }
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(.color1)
                    .cornerRadius(10)
                }
                
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
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
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
                            viewModel.refresh.toggle()
                        },
                        secondaryButton: .cancel())
            }
            
            if let eventDetail = viewModel.eventDetail {
                ZStack {
                    Rectangle()
                        .fill(eventDetail.aEndTime == nil ? .color1 : .success)
                        .frame(height: 40)
                        .cornerRadius(10)

                    HStack {
                        Image(systemName: "checkmark.circle")
                        Text(eventDetail.aEndTime == nil ? "Tick" : "Done")
                    }
                }
                .onTapGesture {
                    guard eventDetail.aEndTime == nil else { return }
                    withAnimation {
                        EventActionHandler.shared.tick(ec: eventDetail)
                        viewModel.refresh.toggle()
                    }
                }
            }
        }
        .foregroundStyle(.cPrimary)
        .padding(.horizontal, K.horizontal_padding)
        .padding(.vertical, K.medium_size)
        .background(Color.cBackground.cornerRadius(30))
        .padding(.horizontal, K.horizontal_padding)
        .onChange(of: viewModel.refresh, { oldValue, newValue in
            
        })
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

#Preview {
    EventDetailPopup(viewModel: ContentViewModel(), showAlert: false)
}
