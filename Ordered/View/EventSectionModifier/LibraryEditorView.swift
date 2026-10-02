import SwiftUI
import CoreData

struct CategoryEditor: View {
    let category: Category?
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\Event.order, order: .forward)],
        predicate: NSPredicate(format: "isActive == true")
    ) private var events: FetchedResults<Event>

    @State private var showCreateEvent = false
    @State private var name: String
    @State private var icon: String
    @State private var selectedEventIDs: [NSManagedObjectID]
    @State private var saveError: String?

    init(category: Category? = nil, onSave: @escaping () -> Void = {}) {
        self.category = category
        self.onSave = onSave
        _name = State(initialValue: category?.name ?? "")
        _icon = State(initialValue: category?.icon ?? "🏷️")
        let ids = (category?.orderedActiveEvents ?? []).map(\.objectID)
        _selectedEventIDs = State(initialValue: ids)
    }

    var body: some View {
        NavigationStack {
            Form {
                SwiftUI.Section("Category") {
                    HStack {
                        TextField("Icon", text: $icon)
                            .frame(width: 52)
                        TextField("Name", text: $name)
                    }
                }

                SwiftUI.Section("Events in Order") {
                    if selectedEventIDs.isEmpty {
                        Text("Add events below, then drag to reorder them.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(selectedEventIDs, id: \.self) { id in
                        if let event = events.first(where: { $0.objectID == id }) {
                            HStack {
                                Text(event.icon ?? "")
                                Text(event.name ?? "Event")
                                Spacer()
                                Button {
                                    selectedEventIDs.removeAll { $0 == id }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.borderless)
                                .accessibilityLabel("Remove \(event.name ?? "event") from category")
                            }
                        }
                    }
                    .onMove { source, destination in
                        selectedEventIDs.move(fromOffsets: source, toOffset: destination)
                    }
                }

                SwiftUI.Section("Add Events") {
                    Button {
                        showCreateEvent = true
                    } label: {
                        Label("Create Event", systemImage: "plus.circle.fill")
                    }

                    if availableEvents.allSatisfy({ selectedEventIDs.contains($0.objectID) }) {
                        Text("No more uncategorized events")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    ForEach(availableEvents.filter { !selectedEventIDs.contains($0.objectID) }) { event in
                        Button {
                            selectedEventIDs.append(event.objectID)
                        } label: {
                            HStack {
                                Text(event.icon ?? "")
                                Text(event.name ?? "Event")
                                Spacer()
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.color3)
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle(category == nil ? "New Category" : "Edit Category")
            .sheet(isPresented: $showCreateEvent) {
                LibraryCreateEventSheet { eventID in
                    selectedEventIDs.append(eventID)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Couldn't Save Category", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) { saveError = nil }
            } message: {
                Text(saveError ?? "Please try again.")
            }
        }
    }

    private var availableEvents: [Event] {
        events.filter { event in
            event.activeCategories.isEmpty || event.category == category
        }
    }

    private func save() {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = Model.viewContext.persistentStoreCoordinator
        do {
            let target: Category
            if let category {
                target = try context.existingObject(with: category.objectID) as! Category
            } else {
                target = Category(context: context)
                let count = Category.count()
                let colors = colorScheme == .dark ? K.categoryColorsDark : K.categoryColors
                target.color = colors[count % colors.count]
                target.order = Int16(count)
            }
            target.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            target.icon = icon.isEmpty ? "🏷️" : icon
            target.isActive = true

            let selectedEvents = try selectedEventIDs.compactMap { id -> Event? in
                guard availableEvents.contains(where: { $0.objectID == id }) else { return nil }
                return try context.existingObject(with: id) as? Event
            }
            for event in target.events?.array as? [Event] ?? [] where !selectedEventIDs.contains(event.objectID) {
                event.category = nil
            }
            for event in selectedEvents {
                event.category = target
                event.categories = NSSet()
            }
            target.events = NSOrderedSet(array: selectedEvents)
            try context.save()
            onSave()
            dismiss()
        } catch {
            context.rollback()
            saveError = error.localizedDescription
        }
    }
}

enum LibraryEditorRoute: Identifiable {
    case category(Category?)

    var id: String {
        switch self {
        case .category(let category):
            return "category-\(category?.objectID.uriRepresentation().absoluteString ?? "new")"
        }
    }
}

struct LibraryEditorView: View {
    @ObservedObject var viewModel: ContentViewModel

    @FetchRequest(
        sortDescriptors: [SortDescriptor(\Category.order, order: .forward)],
        predicate: NSPredicate(format: "isActive == true"),
        animation: .default
    ) private var categories: FetchedResults<Category>

    var body: some View {
        ScrollView {
            categoryList
                .padding(.top, 18)
                .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
        .sheet(item: $viewModel.libraryEditorRoute) { route in
            switch route {
            case .category(let category):
                CategoryEditor(category: category) {
                    viewModel.refresh.toggle()
                }
                .presentationCornerRadius(K.presentationCornerRadius)


            }
        }
    }

    private var categoryList: some View {
        LazyVStack(spacing: 14) {
            ForEach(categories) { category in
                Button {
                    viewModel.libraryEditorRoute = .category(category)
                } label: {
                    LibraryCategoryCard(category: category)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        category.delete()
                        viewModel.refresh.toggle()
                    }
                }
            }

            if categories.isEmpty {
                LibraryEmptyState(
                    icon: "tag",
                    title: "No Categories",
                    message: "Create a category and choose from your uncategorized events."
                )
            }
        }
        .padding(.horizontal, K.horizontal_padding)
    }

}

private struct LibraryCategoryCard: View {
    @ObservedObject var category: Category

    private var events: [Event] {
        category.orderedActiveEvents
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(category.icon ?? "🏷️")
                    .font(.title3)
                    .frame(width: 30, height: 30)
                    .background(Color.white.opacity(0.55), in: Circle())

                Text(category.name ?? "Category")
                    .font(.headline)

                Spacer()

                Text("\(events.count) events")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }

            if events.isEmpty {
                Text("Tap to add uncategorized events")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                LibraryEventPills(events: events)
            }
        }
        .padding(14)
        .background(
            Color(hex: category.color).opacity(0.72),
            in: RoundedRectangle(cornerRadius: 20)
        )
    }
}

private struct LibraryEventPills: View {
    let events: [Event]

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 7) {
                ForEach(Array(events.enumerated()), id: \.offset) { _, event in
                    HStack(spacing: 5) {
                        Text(event.icon ?? "")
                            .font(.caption)
                        Text(event.name ?? "Event")
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.78), in: Capsule())
                }
            }
        }
        .scrollIndicators(.hidden)
    }
}

private struct LibraryEmptyState: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        ContentUnavailableView(title, systemImage: icon, description: Text(message))
            .padding(.top, 70)
    }
}

private struct LibraryCreateEventSheet: View {
    let onCreate: (NSManagedObjectID) -> Void

    @Environment(\.dismiss) private var dismiss
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
                }
            }
            .environment(\.editMode, .constant(.inactive))
            .navigationTitle("Create Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create", action: create)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear { nameTyping = true }
            .alert("Couldn't Create Event", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) { saveError = nil }
            } message: {
                Text(saveError ?? "Please try again.")
            }
        }
    }

    private func create() {
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = Model.viewContext.persistentStoreCoordinator
        do {
            let request: NSFetchRequest<Event> = Event.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Event.order, ascending: false)]
            request.fetchLimit = 1
            let lastOrder = try context.fetch(request).first?.order ?? -1
            let event = Event(context: context)
            event.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            event.icon = emoji.isEmpty ? "💡" : emoji
            event.isActive = true
            event.isFavourite = false
            event.duration = -1
            event.order = lastOrder == Int16.max ? lastOrder : lastOrder + 1

            try context.save()
            onCreate(event.objectID)
            dismiss()
        } catch {
            context.rollback()
            saveError = error.localizedDescription
        }
    }
}
