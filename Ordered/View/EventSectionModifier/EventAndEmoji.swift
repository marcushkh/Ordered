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
    
    @Binding var giveSuggestion: Bool
    @State var showEmojiPicker: Bool = false
    @State var emojiPickerPicked: String = "💡"
    @State var suggestedEmoji: String = ""
    
    @State private var debounceTask: Task<Void, Never>? = nil
    var editEvent_Cal: Event_Cal? = nil
    let data = DataLoader()
    
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
                .onChange(of: emojiPickerPicked, { oldValue, newValue in
                    selectedEmoji = emojiPickerPicked
                    giveSuggestion = false
                })
                .onChange(of: eventName, { oldValue, newValue in
                    debounceTask?.cancel()
                })
                .onChange(of: eventName) { oldValue, newValue in
                    debounceTask = Task {
                        suggestedEmoji = await data.getSuggestion(newValue, top_n: 1)
                        
                        if editEvent_Cal == nil && giveSuggestion {
                            await MainActor.run {
                                selectedEmoji = suggestedEmoji
                            }
                        }
                        
                    }
                }
            Spacer()
            
            eventNameView()
        }
    }

}
