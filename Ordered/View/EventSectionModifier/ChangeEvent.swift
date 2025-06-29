//
//  ChangeEvent.swift
//  Ordered
//
//  Created by Kai Hin Hung on 12/3/2025.
//
import SwiftUI
import MCEmojiPicker

struct ChangeEvent: View{
    @ObservedObject var viewModel: ContentViewModel
    
    @State var icon: String = ""
    @State var name: String = ""
    @FocusState var nameTyping: Bool
    
    @State var showEmojiPicker = false
    @State var showAlert = false
    
    var body : some View{
        ZStack{
            //Background
            Color(.cPrimary.opacity(0.2))
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        dismiss()
                    }
                }
            
            VStack{
                HStack{
                    ZStack{
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.color1))
                            .frame(width: 60, height: 60)
                        
                        Text(icon)
                            .font(.custom("", size: 50))
                            .shadow(radius: K.medium_size)
                            .onTapGesture {
                                showEmojiPicker.toggle()
                            }
                            .emojiPicker(
                                isPresented: $showEmojiPicker,
                                selectedEmoji: $icon
                            )
                    }
                    Spacer()
                    
                    ZStack{
                        TextField("Event", text: $name)
                            .multilineTextAlignment(.leading)
                            .focused($nameTyping)
                            .underlineTextField(underline: .color3, focus: nameTyping, focusColor: Color(.color2))
                            .font(.system(size: 24))
                            .frame(width: 228, height: 80)
                    }
                }
                
                Spacer()
                
                // Two Button Layout - Delete on left, Save on right
                HStack(spacing: 12) {
                    // Delete Button
                    Button(action: {
                        showAlert = true
                    }) {
                        ZStack{
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.error)
                                .frame(height: 40)
                            
                            Image(systemName: "xmark")
                                .font(.title3)
                                .foregroundStyle(Color.white)
                                .bold()
                        }
                    }
                    .frame(width: 60)
                    
                    // Save Button
                    Button(action: {
                        Event.save(
                            icon: icon,
                            name: name,
                            startTime: viewModel.changeEvent?.startTime,
                            endTime: viewModel.changeEvent?.endTime,
                            duration: Int(viewModel.changeEvent?.duration ?? -1),
                            isFavourite: viewModel.changeEvent?.isFavourite ?? false,
                            isActive: viewModel.changeEvent?.isActive ?? true,
                            event: viewModel.changeEvent
                        )
                        dismiss()
                    }) {
                        ZStack{
                            RoundedRectangle(cornerRadius: 20)
                                .fill(name.isEmpty ? Color.gray : Color.color3)
                                .frame(height: 40)
                            
                            HStack {
                                Text("Save")
                            }
                            .font(.title3)
                            .foregroundStyle(Color.white)
                            .bold()
                        }
                    }
                    .disabled(name.isEmpty)
                }
                .padding(.bottom)
            }
            .onAppear{
                icon = viewModel.changeEvent?.icon ?? ""
                name = viewModel.changeEvent?.name ?? ""
                nameTyping = true
            }
            .padding(.vertical)
            .padding(.horizontal)
            .padding(.horizontal, K.horizontal_padding)
            .background()
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Delete Event"),
                    message: Text("Are you sure you want to delete this event?"),
                    primaryButton: .destructive(Text("Delete")) {
                        viewModel.changeEvent?.delete()
                        dismiss()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
    func dismiss(){
        viewModel.changeEvent = nil;
        viewModel.showChangeEvent = false
    }
}

