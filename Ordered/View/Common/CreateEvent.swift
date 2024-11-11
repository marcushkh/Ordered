//
//  CreateEvent.swift
//  Ordered
//
//  Created by Kai Hin Hung on 18/10/2024.
//

import SwiftUI
import MCEmojiPicker


struct CreateEvent: View {
    @State var isPresented: Bool = false
    @State var selectedEmoji: String = "🥱"
    
    @State var eventName: String = ""
    @FocusState var eventNameTyping
    
    var body: some View {
        Background(color: Color(.white), allFocusStates: [$eventNameTyping]){
            VStack{
                HStack{
                    ZStack{
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.color1))
                            .frame(width: 60, height: 60)
                        
                        Text(selectedEmoji)
                            .font(.custom("", size: 50))
                            .shadow(radius: K.medium_size)
                            .onTapGesture {
                                isPresented.toggle()
                            }
                            .emojiPicker(
                                isPresented: $isPresented,
                                selectedEmoji: $selectedEmoji
                            )
                    }
                    .padding(.trailing)
                    
                    TextField("", text: $eventName)
                        
                        .multilineTextAlignment(.leading)
                        .placeholder(when: eventName.isEmpty, alignment: .leading, placeholder: {
                            Text("Event").foregroundStyle(.secondary)
                        })
                        .focused($eventNameTyping)
                        .multilineTextAlignment(.trailing)
                        .underlineTextField(underline: .color3, focus: eventNameTyping, focusColor: Color(.color2))
                        .font(.system(size: 24))
                        .frame(width: 200, height: 80)
                }
                Spacer()
            }
            .padding(.horizontal, K.horizontal_padding * 2)
        }
    }
}

#Preview {
    CreateEvent()
}
