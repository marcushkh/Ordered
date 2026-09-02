//
//  CreateEvent.swift
//  Ordered
//
//  Created by Kai Hin Hung on 18/10/2024.
//

import SwiftUI
import CoreData

/// Creates and edits the app's only supported event kind: a tick event.
struct CreateEvent: View {
    @ObservedObject var viewModel: ContentViewModel

    @FetchRequest(
        sortDescriptors: [SortDescriptor(\Category.order, order: .forward)],
        predicate: NSPredicate(format: "isActive == true")
    ) private var categories: FetchedResults<Category>

    @State var editEvent_Cal: Event_Cal? = nil
    @State var date: Date = Date()

    @State private var selectedEmoji = "💡"
    @State private var eventName = ""
    @FocusState private var eventNameTyping: Bool

    @State private var description = ""
    @FocusState private var descriptionTyping: Bool
    @State private var event: Event? = nil
    @State private var isNewEvent = false
    @State private var selectedCategoryID: NSManagedObjectID?

    @Binding var display: Bool

    var body: some View {
        Background(color: .cBackground, allFocusStates: [$eventNameTyping, $descriptionTyping]) {
            VStack {
                if !isNewEvent && event == nil && editEvent_Cal == nil {
                    eventPicker
                } else {
                    eventDetails
                    Spacer()
                    submitButton
                }
            }
            .padding(.horizontal, K.horizontal_padding * 2)
            .padding(.top)
            .onAppear(perform: initialize)
            .onChange(of: event) { _, newValue in
                guard let newValue else { return }
                selectedEmoji = newValue.icon ?? "💡"
                eventName = newValue.name ?? ""
                selectedCategoryID = newValue.activeCategories.first?.objectID
                descriptionTyping = true
            }
        }
    }

    private var eventPicker: some View {
        VStack {
            EventAndEmoji(
                eventName: $eventName,
                selectedEmoji: $selectedEmoji,
                eventNameTyping: $eventNameTyping
            ) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.color1))
                        .frame(width: 60, height: 60)

                    Text(selectedEmoji)
                        .font(.custom("", size: 50))
                        .shadow(radius: K.medium_size)
                }
            } eventNameView: {
                TextField("Event", text: $eventName)
                    .multilineTextAlignment(.leading)
                    .focused($eventNameTyping)
                    .underlineTextField(underline: .color3, focus: eventNameTyping, focusColor: Color(.color2))
                    .font(.system(size: 24))
                    .frame(width: 228, height: 80)
            }
            .padding(.bottom)

            EventList(
                viewModel: viewModel,
                eventName: $eventName,
                selectedEvent: $event,
                toggleHeartSelectEvent: false
            )

            Spacer()
            newEventButton
        }
    }

    private var eventDetails: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.color1))
                        .frame(width: 60, height: 60)

                    Text(selectedEmoji)
                        .font(.custom("", size: 50))
                        .shadow(radius: K.medium_size)
                }
                .onTapGesture {
                    guard editEvent_Cal == nil else { return }
                    isNewEvent = false
                    event = nil
                }

                Spacer()

                VStack(alignment: .leading, spacing: 8) {
                    Text(eventName + ":")
                        .font(.system(size: 24))

                    TextField("Description (Optional)", text: $description)
                        .focused($descriptionTyping)
                        .underlineTextField(underline: .color3, focus: descriptionTyping, focusColor: Color(.color2))
                        .font(.system(size: 16))
                        .frame(width: 228, height: 16)
                }
            }

            categorySelector
        }
        .padding(.vertical)
    }

    private var categorySelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Menu {
                if categories.isEmpty {
                    Text("Create categories in Quick Add")
                } else {
                    ForEach(categories) { category in
                        Button {
                            toggle(category)
                        } label: {
                            Label(
                                "\(category.icon ?? "🏷️") \(category.name ?? "Category")",
                                systemImage: selectedCategoryID == category.objectID ? "checkmark.circle.fill" : "circle"
                            )
                        }
                    }
                }
            } label: {
                Label("Category", systemImage: "tag")
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
            }

            if let selectedCategory {
                Button {
                    selectedCategoryID = nil
                } label: {
                    Text("\(selectedCategory.icon ?? "🏷️") \(selectedCategory.name ?? "Category")  ×")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color(hex: selectedCategory.color).opacity(0.25), in: Capsule())
                }
                .foregroundStyle(.primary)
            }
        }
    }

    private var selectedCategory: Category? {
        categories.first { $0.objectID == selectedCategoryID }
    }

    private func toggle(_ category: Category) {
        selectedCategoryID = selectedCategoryID == category.objectID ? nil : category.objectID
    }

    private var newEventButton: some View {
        Button {
            guard !eventName.isEmpty else {
                eventNameTyping = true
                return
            }

            if Event.count() >= 20 && !viewModel.isSubscriptionActive {
                viewModel.showCreateEvent = false
                viewModel.isShowPaywall = true
            } else {
                withAnimation {
                    HapticFeedback.light()
                    isNewEvent = true
                    descriptionTyping = true
                }
            }
        } label: {
            actionLabel("New Event")
        }
        .padding(.bottom)
    }

    private var submitButton: some View {
        Button {
            HapticFeedback.light()
            submit()
        } label: {
            actionLabel(editEvent_Cal == nil ? "Add" : "Save")
        }
        .padding(.bottom)
    }

    private func actionLabel(_ title: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.color3)
                .frame(height: 40)

            Text(title)
                .font(.system(size: 20))
                .foregroundStyle(Color.white)
                .bold()
        }
    }

    private func initialize() {
        if let ec = editEvent_Cal {
            event = ec.parent
            eventName = ec.parent?.name ?? ""
            selectedEmoji = ec.parent?.icon ?? "💡"
            selectedCategoryID = ec.parent?.activeCategories.first?.objectID
            description = ec.detail ?? ""
            descriptionTyping = true
        } else {
            eventNameTyping = true
        }
    }

    private func submit() {
        if let ec = editEvent_Cal {
            let tickTime = ec.aEndTime == nil ? nil : (ec.aStartTime ?? ec.aEndTime)
            ec.edit(
                detail: description,
                startTime: nil,
                endTime: nil,
                duration: -1,
                aStartTime: tickTime,
                aEndTime: tickTime,
                parent: event
            )
            event?.setCategory(selectedCategory)

            if viewModel.currentTab == .plan {
                viewModel.highlightedEC = ec
                viewModel.highlightedSC = nil
            }
            display = false
            return
        }

        let parent = event ?? Event.save(
            icon: selectedEmoji,
            name: eventName,
            duration: -1,
            order_insert_first: false
        )
        parent.setCategory(selectedCategory)
        let calendarEvent = parent.getEC()
        calendarEvent.detail = description

        let section = viewModel.createEvent_Section_Cal ?? Section_Cal.new()
        section.add(event: calendarEvent)

        let calendar = Cal.get(date: date.getYYMMDD()) ?? Cal.new(date: date.getYYMMDD())
        calendar.addSection(section)

        if viewModel.currentTab == .plan {
            viewModel.highlightedEC = calendarEvent
        }
        display = false
    }
}
