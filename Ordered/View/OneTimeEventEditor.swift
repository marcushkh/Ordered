import SwiftUI

struct OneTimeEventEditor: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @State private var name = ""
    @State private var emoji = "💡"
    @State private var saveError: String?
    @FocusState private var nameTyping: Bool

    var body: some View {
        NavigationStack {
            Form {
                SwiftUI.Section {
                    EventAndEmoji(eventName: $name, selectedEmoji: $emoji, eventNameTyping: $nameTyping) {
                        Text(emoji.isEmpty ? "💡" : emoji)
                            .font(.system(size: 40))
                            .frame(width: 60, height: 60)
                            .background(Color.color1, in: RoundedRectangle(cornerRadius: 16))
                    } eventNameView: {
                        TextField("Event name", text: $name)
                            .focused($nameTyping)
                            .submitLabel(.done)
                            .onSubmit { nameTyping = false }
                    }
                } footer: {
                    Text("Added to your plan for one-time use. It won’t appear in your Library.")
                }
            }
            .navigationTitle("One-Time Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        do {
                            try PlanStore.createOneTime(name: name, icon: emoji, in: viewContext)
                            HapticFeedback.light()
                            dismiss()
                        } catch { saveError = error.localizedDescription }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear { nameTyping = true }
            .alert("Couldn't Add Event", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) { saveError = nil }
            } message: { Text(saveError ?? "Please try again.") }
        }
    }
}
