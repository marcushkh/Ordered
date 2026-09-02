//
//  EventAndEmoji.swift
//  Ordered
//
//  Created by Kai Hin Hung on 21/5/2025.
//

import SwiftUI
import MCEmojiPicker

struct EventAndEmoji<Emoji: View, EventName: View>: View{
    @Binding var eventName: String
    @Binding var selectedEmoji: String
    
    @FocusState.Binding var eventNameTyping: Bool
    @State var showEmojiPicker: Bool = false
    @State var emojiPickerPicked: String = "💡"
    
    let emojiView: () -> Emoji
    let eventNameView: () -> EventName
    
    var body: some View{
        HStack{
            emojiView()
                .onTapGesture {
                    showEmojiPicker.toggle()
                }
                .emojiPicker(
                    isPresented: $showEmojiPicker,
                    selectedEmoji: $emojiPickerPicked
                )
                .onChange(of: emojiPickerPicked) { _, newValue in
                    selectedEmoji = newValue
                }
            Spacer()
            
            eventNameView()
        }
    }

}
