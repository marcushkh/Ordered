import SwiftUI
import CoreData

struct SelectSection: View {
    @ObservedObject var viewModel: ContentViewModel
    @State private var selectedSection: Section?

    @FetchRequest(
        sortDescriptors: [SortDescriptor(\Section.order, order: .forward)],
        predicate: NSPredicate(format: "isActive == true"),
        animation: .default
    ) private var sections: FetchedResults<Section>

    var body: some View {
        VStack(spacing: 16) {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(sections) { section in
                        SectionInfo(section: section)
                            .padding(12)
                            .background(.color1, in: RoundedRectangle(cornerRadius: 14))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(selectedSection == section ? Color.color3 : .clear, lineWidth: 3)
                            }
                            .onTapGesture { selectedSection = section }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .frame(height: 220)

            Button {
                guard let selectedSection else { return }
                Section_Cal.save(
                    section: selectedSection,
                    sc: viewModel.changeSection_Cal,
                    cal: viewModel.insertToCal,
                    insertIndex: viewModel.insertIndex
                )
                dismiss()
            } label: {
                Text(viewModel.changeSection_Cal == nil ? "Add Section" : "Change Section")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(selectedSection == nil ? Color.gray : Color.color3, in: RoundedRectangle(cornerRadius: 12))
            }
            .disabled(selectedSection == nil)
        }
        .padding(K.horizontal_padding)
        .background(Color.cBackground, in: RoundedRectangle(cornerRadius: 30))
        .padding(.horizontal, K.horizontal_padding)
        .onAppear { selectedSection = viewModel.changeSection_Cal?.parent }
        .onDisappear { dismiss() }
    }

    private func dismiss() {
        viewModel.showSelectSection = false
        viewModel.changeSection_Cal = nil
        viewModel.changeSection = nil
        viewModel.insertToCal = nil
        viewModel.insertIndex = nil
        viewModel.refresh.toggle()
    }
}

struct SectionEditor: View {
    let section: Section?
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\Event.order, order: .forward)],
        predicate: NSPredicate(format: "isActive == true")
    ) private var events: FetchedResults<Event>

    @State private var name: String
    @State private var icon: String
    @State private var eventIDs: [NSManagedObjectID]

    init(section: Section? = nil, onSave: @escaping () -> Void = {}) {
        self.section = section
        self.onSave = onSave
        _name = State(initialValue: section?.name ?? "")
        _icon = State(initialValue: section?.icon ?? "📁")
        let templates = section?.event_cals?.array as? [Event_Cal] ?? []
        let ids = templates.isEmpty
            ? (section?.events?.array as? [Event] ?? []).map(\.objectID)
            : templates.compactMap { $0.parent?.objectID }
        _eventIDs = State(initialValue: ids)
    }

    var body: some View {
        NavigationStack {
            Form {
                SwiftUI.Section("Section") {
                    HStack {
                        TextField("Icon", text: $icon)
                            .frame(width: 52)
                        TextField("Name", text: $name)
                    }
                }

                SwiftUI.Section("Events in Order") {
                    if eventIDs.isEmpty {
                        Text("Add events below. The same event can be added more than once.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    ForEach(Array(eventIDs.enumerated()), id: \.offset) { index, eventID in
                        if let event = events.first(where: { $0.objectID == eventID }) {
                            HStack {
                                Text(event.icon ?? "")
                                Text(event.name ?? "Event")
                                Spacer()
                                Button(role: .destructive) {
                                    eventIDs.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                    .onMove { offsets, destination in
                        eventIDs.move(fromOffsets: offsets, toOffset: destination)
                    }
                }

                SwiftUI.Section("Add Event") {
                    ForEach(events) { event in
                        Button {
                            eventIDs.append(event.objectID)
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
            .navigationTitle(section == nil ? "New Section" : "Edit Section")
            .environment(\.editMode, .constant(.active))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        let target = section ?? Section.new(colorScheme: colorScheme, name: name, icon: icon, count: Section.count())
        target.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        target.icon = icon.isEmpty ? "📁" : icon
        target.isActive = true

        let oldTemplates = target.event_cals?.array as? [Event_Cal] ?? []
        oldTemplates.forEach(Model.viewContext.delete)

        let templates: [Event_Cal] = eventIDs.compactMap { eventID in
            guard let event = events.first(where: { $0.objectID == eventID }) else { return nil }
            let template = Event_Cal(context: Model.viewContext)
            template.parent = event
            template.section = target
            template.duration = -1
            template.startTime = nil
            template.endTime = nil
            return template
        }
        target.event_cals = NSOrderedSet(array: templates)

        // Keep the legacy unique list populated so older migration paths remain
        // safe; the ordered template entries above are the source of truth.
        var seen = Set<NSManagedObjectID>()
        let uniqueEvents = eventIDs.compactMap { eventID -> Event? in
            guard seen.insert(eventID).inserted else { return nil }
            return events.first(where: { $0.objectID == eventID })
        }
        target.events = NSOrderedSet(array: uniqueEvents)
        try? Model.viewContext.save()
        onSave()
        dismiss()
    }
}

struct CategoryEditor: View {
    let category: Category?
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\Event.order, order: .forward)],
        predicate: NSPredicate(format: "isActive == true")
    ) private var events: FetchedResults<Event>

    @State private var name: String
    @State private var icon: String
    @State private var selectedEventIDs: Set<NSManagedObjectID>

    init(category: Category? = nil, onSave: @escaping () -> Void = {}) {
        self.category = category
        self.onSave = onSave
        _name = State(initialValue: category?.name ?? "")
        _icon = State(initialValue: category?.icon ?? "🏷️")
        let ids = (category?.events?.array as? [Event] ?? []).map(\.objectID)
        _selectedEventIDs = State(initialValue: Set(ids))
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

                SwiftUI.Section("Events") {
                    if availableEvents.isEmpty {
                        Text("No uncategorized events")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    ForEach(availableEvents) { event in
                        Button {
                            if selectedEventIDs.contains(event.objectID) {
                                selectedEventIDs.remove(event.objectID)
                            } else {
                                selectedEventIDs.insert(event.objectID)
                            }
                        } label: {
                            HStack {
                                Text(event.icon ?? "")
                                Text(event.name ?? "Event")
                                Spacer()
                                Image(systemName: selectedEventIDs.contains(event.objectID) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedEventIDs.contains(event.objectID) ? .color3 : .secondary)
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
            }
            .navigationTitle(category == nil ? "New Category" : "Edit Category")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private var availableEvents: [Event] {
        events.filter { event in
            event.activeCategories.isEmpty || event.category == category
        }
    }

    private func save() {
        let target = category ?? Category.new(
            colorScheme: colorScheme,
            name: name,
            icon: icon,
            count: Category.count()
        )
        target.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        target.icon = icon.isEmpty ? "🏷️" : icon
        target.isActive = true

        for event in events where event.category == target && !selectedEventIDs.contains(event.objectID) {
            event.setCategory(nil)
        }

        let selectedEvents = availableEvents.filter { selectedEventIDs.contains($0.objectID) }
        for event in selectedEvents {
            event.setCategory(target)
        }
        target.events = NSOrderedSet(array: selectedEvents)
        try? Model.viewContext.save()
        onSave()
        dismiss()
    }
}

private enum LibraryMode: String, CaseIterable, Identifiable {
    case category = "Category"
    case section = "Section"

    var id: String { rawValue }
}

private enum LibraryEditorRoute: Identifiable {
    case category(Category?)
    case section(Section?)
    case quickSection(Section)

    var id: String {
        switch self {
        case .category(let category):
            return "category-\(category?.objectID.uriRepresentation().absoluteString ?? "new")"
        case .section(let section):
            return "section-\(section?.objectID.uriRepresentation().absoluteString ?? "new")"
        case .quickSection(let section):
            return "quick-section-\(section.objectID.uriRepresentation().absoluteString)"
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

    @FetchRequest(
        sortDescriptors: [SortDescriptor(\Section.order, order: .forward)],
        predicate: NSPredicate(format: "isActive == true"),
        animation: .default
    ) private var sections: FetchedResults<Section>

    @State private var mode: LibraryMode = .category
    @State private var route: LibraryEditorRoute?

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Library")
                        .font(.title2.bold())

                    Spacer()

                    Button {
                        route = mode == .category ? .category(nil) : .section(nil)
                    } label: {
                        Image(systemName: "plus.circle")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                }

                Picker("Library", selection: $mode) {
                    ForEach(LibraryMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(.horizontal, K.horizontal_padding)
            .padding(.top, 12)
            .padding(.bottom, 14)
            .background(Color.cBackground)

            ScrollView {
                if mode == .category {
                    categoryList
                } else {
                    sectionList
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(.bottom, 86)
        .sheet(item: $route) { route in
            switch route {
            case .category(let category):
                CategoryEditor(category: category) {
                    viewModel.refresh.toggle()
                }
                .presentationCornerRadius(K.presentationCornerRadius)

            case .section(let section):
                SectionEditor(section: section) {
                    viewModel.refresh.toggle()
                }
                .presentationCornerRadius(K.presentationCornerRadius)

            case .quickSection(let section):
                SectionQuickAddSheet(section: section) {
                    viewModel.refresh.toggle()
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(30)
            }
        }
    }

    private var categoryList: some View {
        LazyVStack(spacing: 14) {
            ForEach(categories) { category in
                Button {
                    route = .category(category)
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
        .padding(.top, 4)
    }

    private var sectionList: some View {
        LazyVStack(spacing: 12) {
            ForEach(sections) { section in
                LibrarySectionCard(section: section) {
                    route = .section(section)
                }
                .contentShape(RoundedRectangle(cornerRadius: 20))
                .onTapGesture {
                    route = .quickSection(section)
                }
                .contextMenu {
                    Button("Edit Details", systemImage: "pencil") {
                        route = .section(section)
                    }
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        section.delete()
                        viewModel.refresh.toggle()
                    }
                }
            }

            if sections.isEmpty {
                LibraryEmptyState(
                    icon: "rectangle.stack",
                    title: "No Sections",
                    message: "Create a reusable section, then quick-add events to it."
                )
            }
        }
        .padding(.horizontal, K.horizontal_padding)
        .padding(.top, 4)
    }
}

private struct LibraryCategoryCard: View {
    @ObservedObject var category: Category

    private var events: [Event] {
        (category.events?.array as? [Event] ?? []).filter(\.isActive)
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

private struct LibrarySectionCard: View {
    @ObservedObject var section: Section
    let edit: () -> Void

    private var events: [Event] {
        let templates = section.event_cals?.array as? [Event_Cal] ?? []
        if templates.isEmpty {
            return section.events?.array as? [Event] ?? []
        }
        return templates.compactMap(\.parent)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(section.icon ?? "📁")
                    .font(.title3)
                    .frame(width: 30, height: 30)
                    .background(Color(hex: section.color).opacity(0.7), in: Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(section.name ?? "Section")
                        .font(.headline)
                    Text("\(events.count) events")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: edit) {
                    Image(systemName: "pencil")
                        .font(.subheadline)
                        .frame(width: 30, height: 30)
                        .background(Color.color1, in: Circle())
                }
                .buttonStyle(.plain)

                Image(systemName: "chevron.up")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }

            if events.isEmpty {
                Text("Tap to quick-add events")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                LibraryEventPills(events: Array(events.prefix(6)))
            }
        }
        .padding(14)
        .background(Color.color1.opacity(0.75), in: RoundedRectangle(cornerRadius: 20))
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

private struct SectionQuickAddSheet: View {
    @ObservedObject var section: Section
    let onChange: () -> Void

    @FetchRequest(
        sortDescriptors: [
            SortDescriptor(\Event.isFavourite, order: .reverse),
            SortDescriptor(\Event.order, order: .forward)
        ],
        predicate: NSPredicate(format: "isActive == true"),
        animation: .default
    ) private var events: FetchedResults<Event>

    @State private var refresh = false

    private var templates: [Event_Cal] {
        section.event_cals?.array as? [Event_Cal] ?? []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(section.icon ?? "📁")
                    .font(.title3)
                Text(section.name ?? "Section")
                    .font(.title3.bold())
                Spacer()
                Text("\(templates.count) events")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !templates.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(Array(templates.enumerated()), id: \.offset) { index, template in
                            if let event = template.parent {
                                HStack(spacing: 5) {
                                    Text(event.icon ?? "")
                                        .font(.caption)
                                    Text(event.name ?? "Event")
                                        .font(.caption)
                                        .lineLimit(1)
                                    Button {
                                        removeTemplate(at: index)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 9)
                                .padding(.vertical, 7)
                                .background(Color(hex: event.activeCategories.first?.color).opacity(0.55), in: Capsule())
                            }
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }

            Divider()

            Text("Tap to Add")
                .font(.headline)

            ScrollView {
                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 10
                ) {
                    ForEach(events) { event in
                        Button {
                            add(event)
                        } label: {
                            HStack(spacing: 8) {
                                Text(event.icon ?? "")
                                    .font(.title3)
                                Text(event.name ?? "Event")
                                    .font(.subheadline)
                                    .lineLimit(1)
                                Spacer(minLength: 0)
                                Image(systemName: "plus.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.color3)
                            }
                            .padding(.horizontal, 10)
                            .frame(minHeight: 46)
                            .background(
                                Color(hex: event.activeCategories.first?.color).opacity(0.55),
                                in: RoundedRectangle(cornerRadius: 14)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, K.horizontal_padding)
        .padding(.bottom, K.medium_size)
        .onAppear { materializeLegacyTemplates() }
        .onChange(of: refresh) { _, _ in }
    }

    private func materializeLegacyTemplates() {
        guard templates.isEmpty else { return }
        let legacyEvents = section.events?.array as? [Event] ?? []
        guard !legacyEvents.isEmpty else { return }

        let newTemplates = legacyEvents.map { event in
            makeTemplate(for: event)
        }
        section.event_cals = NSOrderedSet(array: newTemplates)
        saveChanges()
    }

    private func add(_ event: Event) {
        let items = section.event_cals?.mutableCopy() as? NSMutableOrderedSet ?? NSMutableOrderedSet()
        items.add(makeTemplate(for: event))
        section.event_cals = items.copy() as? NSOrderedSet

        let uniqueEvents = section.events?.mutableCopy() as? NSMutableOrderedSet ?? NSMutableOrderedSet()
        if !uniqueEvents.contains(event) {
            uniqueEvents.add(event)
            section.events = uniqueEvents.copy() as? NSOrderedSet
        }
        HapticFeedback.light()
        saveChanges()
    }

    private func removeTemplate(at index: Int) {
        guard templates.indices.contains(index) else { return }
        let template = templates[index]
        let removedEvent = template.parent
        let items = section.event_cals?.mutableCopy() as? NSMutableOrderedSet ?? NSMutableOrderedSet()
        items.removeObject(at: index)
        section.event_cals = items.copy() as? NSOrderedSet
        Model.viewContext.delete(template)

        if let removedEvent,
           !(section.event_cals?.array as? [Event_Cal] ?? []).contains(where: { $0.parent == removedEvent }) {
            let uniqueEvents = section.events?.mutableCopy() as? NSMutableOrderedSet ?? NSMutableOrderedSet()
            uniqueEvents.remove(removedEvent)
            section.events = uniqueEvents.copy() as? NSOrderedSet
        }
        saveChanges()
    }

    private func makeTemplate(for event: Event) -> Event_Cal {
        let template = Event_Cal(context: Model.viewContext)
        template.parent = event
        template.section = section
        template.duration = -1
        template.durationFinished = 0
        template.startTime = nil
        template.endTime = nil
        template.aStartTime = nil
        template.aEndTime = nil
        return template
    }

    private func saveChanges() {
        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to update section template: \(error.localizedDescription)")
        }
        refresh.toggle()
        onChange()
    }
}
