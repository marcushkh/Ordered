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
                            .frame(width: 200, height: 80)
                    }
                    
                    Button{
                        showAlert = true
                    } label: {
                        Image(systemName: "x.square.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 30)
                            .foregroundStyle(.error)
                    }
                    
                }
                Spacer()
                
                Button {
                    Event.save(icon: icon, name: name, event: viewModel.changeEvent)
                    dismiss()
                } label: {
                    ZStack{
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.color3)
                            .frame(height: 40)
                        
                        Text("Change Event")
                            .font(.system(size: 20))
                            .foregroundStyle(Color(.white))
                            .bold()
                        
                    }
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

