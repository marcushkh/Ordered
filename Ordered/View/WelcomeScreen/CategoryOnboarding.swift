import SwiftUI

struct CategoryOnboarding: View {
    @ObservedObject var welcomeVM: WelcomeVM
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingCustomEvent = false
    let onComplete: () -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 3)

    private var categoryColor: Color {
        let palette = colorScheme == .dark ? K.categoryColorsDark : K.categoryColors
        return Color(hex: palette[welcomeVM.categoryIndex % palette.count])
    }

    var body: some View {
        if welcomeVM.categoriesComplete {
            VStack(spacing: 20) {
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(.success)
                Text("Your categories are ready")
                    .font(.title2.bold())
                Text("You can add or edit categories and events in Library anytime.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Spacer()
                continueButton("Next", action: onComplete)
            }
        } else {
            let category = welcomeVM.categoryDrafts[welcomeVM.categoryIndex]
            let selectedCount = category.events.filter(\.isSelected).count
            VStack(spacing: 16) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("\(category.icon)  \(category.name)")
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 9)
                                .background(categoryColor, in: Capsule())

                            Text(category.question)
                                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(category.events) { event in
                                Button {
                                    toggleEvent(event.id)
                                } label: {
                                    QuickFinishCardContent(
                                        name: event.name, icon: event.icon, color: categoryColor,
                                        finishedCount: event.isSelected ? 1 : 0,
                                        statusText: event.isSelected ? "Added!" : "Add",
                                        draftCelebrationID: event.id
                                    )
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("\(event.name), \(event.isSelected ? "Added" : "Not added")")
                                .accessibilityHint(event.isSelected ? "Tap to remove" : "Tap to add")
                                .accessibilityAddTraits(event.isSelected ? .isSelected : [])
                            }

                            Button { showingCustomEvent = true } label: {
                                QuickFinishCardContent(
                                    name: "Custom Event", icon: "", color: categoryColor,
                                    finishedCount: 0, statusText: "Create", systemIcon: "plus"
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Create custom event")
                        }
                    }
                    .padding(.vertical)
                }
                .scrollIndicators(.hidden)
                .id(welcomeVM.categoryIndex)

                continueButton(selectedCount == 0 ? "Skip" : "Create Category", action: advance)
            }
            .sheet(isPresented: $showingCustomEvent) {
                OnboardingCustomEventEditor { name, icon in
                    let event = OnboardingEvent(name: name, icon: icon, isSelected: true)
                    welcomeVM.categoryDrafts[welcomeVM.categoryIndex].events.append(event)
                    HapticFeedback.soft()
                    EventCompletionCelebrations.shared.celebrate(draftID: event.id)
                }
            }
        }
    }

    private func continueButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Spacer()
                Text(title)
                Image(systemName: "arrow.right")
                Spacer()
            }
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 20)
            .padding(.vertical)
            .background(Color(hex: "484B6A"), in: RoundedRectangle(cornerRadius: 20))
        }
    }

    private func toggleEvent(_ id: UUID) {
        guard let index = welcomeVM.categoryDrafts[welcomeVM.categoryIndex].events.firstIndex(where: { $0.id == id }) else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            welcomeVM.categoryDrafts[welcomeVM.categoryIndex].events[index].isSelected.toggle()
        }
        let isSelected = welcomeVM.categoryDrafts[welcomeVM.categoryIndex].events[index].isSelected
        if isSelected {
            HapticFeedback.soft()
            EventCompletionCelebrations.shared.celebrate(draftID: id)
        } else {
            HapticFeedback.light()
            EventCompletionCelebrations.shared.cancel(draftID: id)
        }
    }

    private func advance() {
        for event in welcomeVM.categoryDrafts[welcomeVM.categoryIndex].events {
            EventCompletionCelebrations.shared.cancel(draftID: event.id)
        }
        HapticFeedback.light()
        withAnimation {
            welcomeVM.advanceCategory()
            if welcomeVM.categoriesComplete { onComplete() }
        }
    }
}

private struct OnboardingCustomEventEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var icon = "💡"
    @FocusState private var nameFocused: Bool
    let onAdd: (String, String) -> Void

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                EventAndEmoji(eventName: $name, selectedEmoji: $icon, eventNameTyping: $nameFocused) {
                    Text(icon).font(.largeTitle)
                        .frame(width: 50, height: 50)
                } eventNameView: {
                    TextField("Event Name", text: $name)
                        .focused($nameFocused)
                        .submitLabel(.done)
                        .onSubmit(add)
                }
            }
            .navigationTitle("Custom Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add", action: add).disabled(trimmedName.isEmpty)
                }
            }
            .onAppear { nameFocused = true }
        }
    }

    private func add() {
        guard !trimmedName.isEmpty else { return }
        onAdd(trimmedName, icon.isEmpty ? "💡" : icon)
        dismiss()
    }
}
