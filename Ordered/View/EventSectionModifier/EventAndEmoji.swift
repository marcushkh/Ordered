//
//  EventAndEmoji.swift
//  Ordered
//
//  Created by Kai Hin Hung on 21/5/2025.
//

import SwiftUI
import UIKit

struct EventAndEmoji<Emoji: View, EventName: View>: View {
    @Binding var eventName: String
    @Binding var selectedEmoji: String
    @FocusState.Binding var eventNameTyping: Bool

    let emojiView: () -> Emoji
    let eventNameView: () -> EventName

    var body: some View {
        HStack {
            emojiView()
                .accessibilityHidden(true)
                .overlay {
                    NativeEmojiInput(emoji: $selectedEmoji) {
                        eventNameTyping = false
                    }
                }

            Spacer()
            eventNameView()
        }
    }
}

/// Uses the system emoji input mode when installed, with the normal keyboard as fallback.
final class EmojiKeyboardTextField: UITextField {
    override var textInputContextIdentifier: String? { "ordered.eventEmoji" }

    override var textInputMode: UITextInputMode? {
        UITextInputMode.activeInputModes.first { $0.primaryLanguage == "emoji" }
            ?? super.textInputMode
    }
}

/// The existing emoji artwork remains visible underneath this native input control.
struct NativeEmojiInput: UIViewRepresentable {
    @Binding var emoji: String
    var onBeginEditing: () -> Void = {}

    func makeUIView(context: Context) -> EmojiKeyboardTextField {
        let field = EmojiKeyboardTextField()
        field.delegate = context.coordinator
        field.text = emoji
        field.textColor = .clear
        field.tintColor = .clear
        field.font = .systemFont(ofSize: 50)
        field.textAlignment = .center
        field.autocorrectionType = .no
        field.spellCheckingType = .no
        field.returnKeyType = .done
        field.accessibilityLabel = "Event emoji"
        field.accessibilityHint = "Type an emoji using the keyboard"
        field.accessibilityValue = emoji
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let toolbar = UIToolbar()
        toolbar.items = [
            UIBarButtonItem(systemItem: .flexibleSpace),
            UIBarButtonItem(title: "Done", style: .done, target: field, action: #selector(UIResponder.resignFirstResponder))
        ]
        toolbar.sizeToFit()
        field.inputAccessoryView = toolbar
        return field
    }

    func updateUIView(_ field: EmojiKeyboardTextField, context: Context) {
        context.coordinator.parent = self
        if field.text != emoji { field.text = emoji }
        field.accessibilityValue = emoji
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject, UITextFieldDelegate {
        var parent: NativeEmojiInput

        init(parent: NativeEmojiInput) { self.parent = parent }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.onBeginEditing()
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            if string.isEmpty {
                textField.text = ""
                parent.emoji = ""
                return false
            }
            // Character preserves joined emoji, flags, and skin-tone modifiers.
            guard let emoji = string.last(where: { character in
                character.unicodeScalars.contains { $0.properties.isEmojiPresentation }
                    || (character.unicodeScalars.count > 1
                        && character.unicodeScalars.contains { $0.properties.isEmoji })
            }) else { return false }
            let value = String(emoji)
            textField.text = value
            textField.accessibilityValue = value
            parent.emoji = value
            return false
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            if parent.emoji.isEmpty {
                parent.emoji = "💡"
                textField.text = parent.emoji
            }
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
    }
}
