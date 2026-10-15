import Foundation

/// Finish/delete are hands-on; the rest of the tour explains controls without editing data.
struct AppTutorial {
    enum Step: Int, CaseIterable {
        case planAdd
        case finishEvent, completedTab, shareDay, deleteCompletion, libraryTab, categoryPlus
        case openCategory, createEvent, statisticsTab, pinEvent, unpinEvent, statistics

        var requiresInteraction: Bool {
            switch self {
            case .finishEvent, .completedTab, .deleteCompletion, .libraryTab, .statisticsTab: return true
            default: return false
            }
        }

        var title: String {
            switch self {
            case .planAdd: return "Add a one-time event"
            case .finishEvent: return "Finish an event!"
            case .completedTab: return "See what you’ve done"
            case .shareDay: return "Share your day with friends"
            case .deleteCompletion: return "Undo a completion"
            case .libraryTab: return "Your event library"
            case .categoryPlus: return "Create a category"
            case .openCategory: return "Your categories"
            case .createEvent: return "Add an event"
            case .statisticsTab: return "See your progress"
            case .pinEvent: return "Pin an event"
            case .unpinEvent: return "Unpin an event"
            case .statistics: return "You’re ready!"
            }
        }

        var message: String {
            switch self {
            case .planAdd: return "The one-time event stays in your plan until you finish it and won’t be added to your Library."
            case .finishEvent: return "Tap an event to mark it finished. Try it now!"
            case .completedTab: return "Tap the list tab to see your completed events."
            case .shareDay: return "We prepare an image for you to share to your friend! Let them know how productive you are!"
            case .deleteCompletion: return "Tap the trash icon to delete the completion you just made."
            case .libraryTab: return "Tap Library to organize your categories and events."
            case .categoryPlus: return "The plus in the top-right corner is where you create a category."
            case .openCategory: return "Open any category to manage its events. Next, we’ll show you where to add an event."
            case .createEvent: return "This is where you create an event to a category."
            case .statisticsTab: return "Tap the chart tab to explore your statistics."
            case .pinEvent: return "The pin beside an event keeps it at the top of your statistics list."
            case .unpinEvent: return "When an event is pinned, this button shows a filled pin. Tap it again to unpin the event and restore its normal order."
            case .statistics: return "Track your completed events over time, change the period, and tap an event for more detail. You’re ready to start!"
            }
        }
    }

    var step: Step?
    private var hasEvents = false
    private(set) var completionID: String?
    private(set) var categoryID: String?
    private(set) var pinEventID: String?
    var isActive: Bool { step != nil }

    mutating func start(hasEvents: Bool, categoryID: String? = nil, pinEventID: String? = nil) {
        completionID = nil
        self.categoryID = categoryID
        self.pinEventID = pinEventID
        self.hasEvents = hasEvents
        step = hasEvents ? .finishEvent : .planAdd
    }

    mutating func finishedEvent(completionID: String) {
        guard step == .finishEvent else { return }
        self.completionID = completionID
        step = .planAdd
    }

    mutating func openedTab(_ tab: String) {
        switch (step, tab) {
        case (.completedTab, "view"): step = .shareDay
        case (.libraryTab, "library"): step = .categoryPlus
        case (.statisticsTab, "statistic"): step = .pinEvent
        default: break
        }
    }

    mutating func deletedCompletion(id: String) {
        guard step == .deleteCompletion, completionID == id else { return }
        completionID = nil
        step = .libraryTab
    }

    /// Informational steps can advance without saving or changing any records.
    mutating func next() {
        switch step {
        case .planAdd: step = hasEvents ? .completedTab : .libraryTab
        case .shareDay: step = .deleteCompletion
        case .categoryPlus: step = .openCategory
        case .openCategory: step = .createEvent
        case .createEvent: step = .statisticsTab
        case .pinEvent: step = .unpinEvent
        case .unpinEvent: step = .statistics
        default: break
        }
    }

    mutating func finish() {
        step = nil
        completionID = nil
        categoryID = nil
        pinEventID = nil
    }
}
