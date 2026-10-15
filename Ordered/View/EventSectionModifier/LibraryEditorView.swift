import SwiftUI
import CoreData
import UIKit
import RevenueCatUI
import RevenueCat

struct CategoryEditor: View {
    @ObservedObject var viewModel: ContentViewModel
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
    @State private var hasUnsavedChanges = false
    @State private var editMode: EditMode = .inactive
    @State private var eventToDelete: Event?
    @State private var eventToEdit: Event?
    @State private var deleteError: String?
    @FocusState private var nameTyping: Bool

    init(viewModel: ContentViewModel, category: Category? = nil, onSave: @escaping () -> Void = {}) {
        self.viewModel = viewModel
        self.category = category
        self.onSave = onSave
        _name = State(initialValue: category?.name ?? "")
        _icon = State(initialValue: category?.icon ?? "🏷️")
        let ids = (category?.orderedActiveEvents ?? []).map(\.objectID)
        _selectedEventIDs = State(initialValue: ids)
    }

    var body: some View {
        NavigationStack {
            editorContent
            .alert("Delete Event?", isPresented: Binding(
                get: { eventToDelete != nil },
                set: { if !$0 { eventToDelete = nil } }
            ), presenting: eventToDelete) { event in
                Button("Delete", role: .destructive) {
                    delete(event)
                }
                Button("Cancel", role: .cancel) { eventToDelete = nil }
            } message: { event in
                Text("Are you sure you want to delete \"\(event.name ?? "Event")\"? It will be removed from your Library. Past completions will be kept.")
            }
            .alert("Couldn't Delete Event", isPresented: Binding(
                get: { deleteError != nil },
                set: { if !$0 { deleteError = nil } }
            )) {
                Button("OK", role: .cancel) { deleteError = nil }
            } message: {
                Text(deleteError ?? "Please try again.")
            }
            .alert("Couldn't Save Category", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("Retry") { _ = save() }
                Button("OK", role: .cancel) { saveError = nil }
            } message: {
                Text(saveError ?? "Please try again.")
            }
        }
        .tutorialShowCase(viewModel)
    }

    private var categoryForm: some View {
        ScrollViewReader { proxy in
        Form {
            categoryFieldsSection
            selectedEventsSection
            addEventsSection
        }
        .background {
            CategoryWhitespaceTapHandler {
                nameTyping = false
            }
        }
        .onChange(of: viewModel.tutorial.step, initial: true) { _, step in
            if step == .createEvent { proxy.scrollTo("tutorialCreateEvent", anchor: .center) }
        }
        }
    }

    private var editorContent: some View {
        categoryForm
        .environment(\.editMode, $editMode)
        .navigationTitle(category == nil ? "New Category" : "Edit Category")
        .navigationBarTitleDisplayMode(.inline)
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showCreateEvent) {
            LibraryCreateEventSheet(viewModel: viewModel) { eventID in
                selectedEventIDs.append(eventID)
            }
        }
        .sheet(item: $eventToEdit) { event in
            ChangeEvent(viewModel: viewModel, event: event)
        }
        .toolbar { editorToolbar }
        .onChange(of: name) { _, _ in autoSave() }
        .onChange(of: icon) { _, _ in autoSave() }
        .onChange(of: selectedEventIDs) { _, _ in autoSave() }
        .interactiveDismissDisabled(category != nil && (name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || hasUnsavedChanges))
    }

    @ToolbarContentBuilder
    private var editorToolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            reorderButton
        }
        if category == nil {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Create") {
                    if save() { dismiss() }
                }
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private var reorderButton: some View {
        Button(editMode.isEditing ? "Done" : "Edit") {
            withAnimation {
                editMode = editMode.isEditing ? .inactive : .active
            }
        }
        .accessibilityLabel(editMode.isEditing ? "Finish reordering events" : "Reorder events")
    }

    private var categoryFieldsSection: some View {
        SwiftUI.Section("Category") {
            Label {
                TextField("Name", text: $name)
                    .focused($nameTyping)

            } icon: {
                Text(icon.isEmpty ? "🏷️" : icon)
                    .accessibilityHidden(true)
                    .overlay {
                        NativeEmojiInput(emoji: $icon,
                                         accessibilityLabel: "Category emoji",
                                         fallbackEmoji: "🏷️")
                    }
            }
        }
    }

    private var selectedEventsSection: some View {
        SwiftUI.Section("Events") {
            if selectedEventIDs.isEmpty {
                Text("Add events below.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            ForEach(selectedEvents) { event in
                selectedEventRow(for: event, id: event.objectID)
            }
            .onMove { source, destination in
                selectedEventIDs.move(fromOffsets: source, toOffset: destination)
            }
        }
    }

    private var addEventsSection: some View {
        SwiftUI.Section("Add Events") {
            Button {
                showCreateEvent = true
            } label: {
                Label("Create Event", systemImage: "plus.circle.fill")
            }
            .id("tutorialCreateEvent")
            .foregroundStyle(.color3)
            .showCase(.createEvent)

            if availableEvents.allSatisfy({ selectedEventIDs.contains($0.objectID) }) {
            }
            ForEach(availableEvents.filter { !selectedEventIDs.contains($0.objectID) }) { event in
                availableEventRow(for: event)
            }
        }
    }

    private var availableEvents: [Event] {
        events.filter { event in
            event.activeCategories.isEmpty || event.category == category
        }
    }

    private var selectedEvents: [Event] {
        selectedEventIDs.compactMap { id in
            events.first(where: { $0.objectID == id })
        }
    }

    @ViewBuilder
    private func selectedEventContent(for id: NSManagedObjectID) -> some View {
        if let event = selectedEvent(for: id) {
            selectedEventRow(for: event, id: id)
        }
    }

    private func selectedEvent(for id: NSManagedObjectID) -> Event? {
        events.first { event in event.objectID == id }
    }

    private func selectedEventRow(for event: Event, id: NSManagedObjectID) -> some View {
        HStack {
            Button {
                eventToEdit = event
            } label: {
                Label {
                    HStack {
                        Text(event.name ?? "Event")
                        Spacer()
                        Image(systemName: "pencil")
                            .foregroundStyle(.color3)
                    }
                } icon: {
                    Text(event.icon ?? "")
                }
                .foregroundStyle(.cPrimary)
                .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Edit \(event.name ?? "event")")
            Button {
                selectedEventIDs.removeAll { $0 == id }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Remove \(event.name ?? "event") from category")
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button("Delete", systemImage: "trash") { eventToDelete = event }
                .tint(.red)
        }
    }

    private func availableEventRow(for event: Event) -> some View {
        Button {
            selectedEventIDs.append(event.objectID)
        } label: {
            Label {
                HStack {
                    Text(event.name ?? "Event")
                    Spacer()
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.color3)
                }
            } icon: {
                Text(event.icon ?? "")
            }
        }
        .foregroundStyle(.primary)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button("Delete", systemImage: "trash") {
                eventToDelete = event
            }
            .tint(.red)
        }
    }

    private func delete(_ event: Event) {
        eventToDelete = nil
        // Save only the deactivation, leaving category drafts and completion history intact.
        let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = Model.viewContext.persistentStoreCoordinator
        do {
            let target = try context.existingObject(with: event.objectID) as! Event
            target.isActive = false
            try context.save()
            selectedEventIDs.removeAll { $0 == event.objectID }
            viewModel.refresh.toggle()
        } catch {
            context.rollback()
            deleteError = error.localizedDescription
        }
    }

    private func autoSave() {
        guard category != nil else { return }
        hasUnsavedChanges = true
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        _ = save()
    }

    @discardableResult
    private func save() -> Bool {
        hasUnsavedChanges = true
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            saveError = "Enter a category name before closing."
            return false
        }
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
            saveError = nil
            hasUnsavedChanges = false
            onSave()
            return true
        } catch {
            context.rollback()
            saveError = error.localizedDescription
            return false
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
        ScrollViewReader { proxy in
        ScrollView {
            categoryList
                .padding(.top, 18)
                .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
        .onChange(of: viewModel.tutorial.step, initial: true) { _, step in
            if step == .openCategory, let id = viewModel.tutorial.categoryID {
                proxy.scrollTo(id, anchor: .center)
            }
        }
        .onChange(of: categories.map(\.objectID)) { _, _ in
            if viewModel.tutorial.step == .openCategory, let id = viewModel.tutorial.categoryID {
                proxy.scrollTo(id, anchor: .center)
            }
        }
        }
        .sheet(item: $viewModel.libraryEditorRoute, onDismiss: {
            viewModel.presentTutorialFollowUpIfNeeded()
        }) { route in
            switch route {
            case .category(let category):
                CategoryEditor(viewModel: viewModel, category: category) {
                    viewModel.refresh.toggle()
                }
                .presentationCornerRadius(K.presentationCornerRadius)
                .interactiveDismissDisabled(viewModel.tutorial.isActive)


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
                .id(category.objectID.uriRepresentation().absoluteString)
                .showCase(.openCategory, enabled: category.objectID.uriRepresentation().absoluteString == viewModel.tutorial.categoryID)
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
    @ObservedObject var viewModel: ContentViewModel
    let onCreate: (NSManagedObjectID) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var emoji = "💡"
    @State private var saveError: String?
    @State private var creationGate = EventCreationGate()
    @State private var showCreationPaywall = false
    @State private var hasCreatedEvent = false
    @State private var isCheckingAccess = false
    @State private var accessCheckTask: Task<Void, Never>?
    @FocusState private var nameTyping: Bool

    var body: some View {
        NavigationStack {
            EventDetailsForm(name: $name, emoji: $emoji, nameTyping: $nameTyping)
            .navigationTitle("Create Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create", action: requestCreation)
                        .disabled(isCheckingAccess || hasCreatedEvent || name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear { nameTyping = true }
            .sheet(isPresented: $showCreationPaywall, onDismiss: finishCreationPaywall) {
                PaywallView(displayCloseButton: true)
                    .onPurchaseCompleted { customerInfo in
                        confirmCreationPremium(customerInfo)
                    }
                    .onRestoreCompleted { customerInfo in
                        confirmCreationPremium(customerInfo)
                    }
            }
            .onChange(of: viewModel.isSubscriptionActive) { _, isActive in
                if isActive && showCreationPaywall {
                    creationGate.confirmPremium(true)
                    showCreationPaywall = false
                }
            }
            .onDisappear { accessCheckTask?.cancel() }
            .alert("Couldn't Create Event", isPresented: Binding(
                get: { saveError != nil },
                set: { if !$0 { saveError = nil } }
            )) {
                Button("OK", role: .cancel) { saveError = nil }
            } message: {
                Text(saveError ?? "Please try again.")
            }
        }
        .tutorialShowCase(viewModel)
    }

    private func requestCreation() {
        guard !isCheckingAccess, !hasCreatedEvent, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard Event.count() >= EventCreationGate.freeEventLimit else {
            create()
            return
        }
        isCheckingAccess = true
        accessCheckTask = Task { @MainActor in
            defer { isCheckingAccess = false }
            do {
                let hasPremium = try await viewModel.checkPremiumAccess()
                try Task.checkCancellation()
                if creationGate.requestCreation(eventCount: Event.count(), hasPremium: hasPremium) {
                    create()
                } else {
                    nameTyping = false
                    showCreationPaywall = true
                }
            } catch is CancellationError {
                // Closing the editor cancels its pending access check.
            } catch {
                saveError = "Unable to verify your subscription. Please try again. \(error.localizedDescription)"
            }
        }
    }

    private func confirmCreationPremium(_ customerInfo: CustomerInfo) {
        viewModel.updateSubscription(customerInfo)
        guard viewModel.isSubscriptionActive else { return }
        creationGate.confirmPremium(true)
        showCreationPaywall = false
    }

    private func finishCreationPaywall() {
        if creationGate.finishPaywall() {
            create()
        } else {
            nameTyping = true
        }
    }

    private func create() {
        guard !hasCreatedEvent else { return }
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
            hasCreatedEvent = true
            onCreate(event.objectID)
            dismiss()
        } catch {
            context.rollback()
            saveError = error.localizedDescription
        }
    }
}

/// Dismiss focus from the form's background without competing with row controls.
private struct CategoryWhitespaceTapHandler: UIViewControllerRepresentable {
    var onTap: () -> Void

    func makeUIViewController(context: Context) -> Controller { Controller() }

    func updateUIViewController(_ controller: Controller, context: Context) {
        controller.onTap = onTap
        DispatchQueue.main.async { [weak controller] in
            controller?.attachRecognizer()
        }
    }

    static func dismantleUIViewController(_ controller: Controller, coordinator: ()) {
        controller.tapRecognizer.view?.removeGestureRecognizer(controller.tapRecognizer)
    }

    final class Controller: UIViewController, UIGestureRecognizerDelegate {
        var onTap: (() -> Void)?
        lazy var tapRecognizer: UITapGestureRecognizer = {
            let recognizer = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
            recognizer.cancelsTouchesInView = false
            recognizer.delaysTouchesBegan = false
            recognizer.delaysTouchesEnded = false
            recognizer.delegate = self
            return recognizer
        }()

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            attachRecognizer()
        }

        func attachRecognizer() {
            guard let host = parent?.view, tapRecognizer.view !== host else { return }
            tapRecognizer.view?.removeGestureRecognizer(tapRecognizer)
            host.addGestureRecognizer(tapRecognizer)
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            var candidate = touch.view
            while let view = candidate {
                // SwiftUI Form buttons live inside collection/table cells.
                // Ignore every row, including text fields and emoji controls.
                if view is UIControl || view is UICollectionViewCell || view is UITableViewCell {
                    return false
                }
                candidate = view.superview
            }
            return true
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            true
        }

        @objc private func backgroundTapped() {
            tapRecognizer.view?.endEditing(true)
            onTap?()
        }
    }
}
