//
//  ContentViewModel.swift
//  Ordered
//
//  Created by Kai Hin Hung on 31/7/2024.
//

import CoreData
import SwiftUI
import RevenueCat

@MainActor
class ContentViewModel: ObservableObject{
    
    @Published var quickFinishOrders = QuickFinishOrderSettings.load() {
        didSet { quickFinishOrders.save() }
    }
    @Published var tutorial = AppTutorial()
    private var tutorialFollowUpPending = false
    @AppStorage("appTutorialPending") var appTutorialPending = false

    func startTutorialIfNeeded() {
        guard appTutorialPending, !tutorial.isActive else { return }
        currentTab = .quick
        planBarExpansion = 0
        quickFinishSearchText = ""
        quickFinishOrders.selectedID = nil
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == true")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Category.order, ascending: true)]
        let category = (try? Model.viewContext.fetch(request))?.first
        let event = category?.orderedActiveEvents.first ?? Event.fetchEvents().first
        tutorial.start(hasEvents: Event.count() > 0,
                       categoryID: category?.objectID.uriRepresentation().absoluteString,
                       pinEventID: event?.objectID.uriRepresentation().absoluteString)
    }

    func nextTutorialStep() {
        if tutorial.step == .openCategory, let id = tutorial.categoryID,
           let url = URL(string: id),
           let objectID = Model.viewContext.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url),
           let category = try? Model.viewContext.existingObject(with: objectID) as? Category {
            libraryEditorRoute = .category(category)
        }
        tutorial.next()
        if tutorial.step == .statisticsTab { libraryEditorRoute = nil }
    }

    func finishTutorial() {
        tutorial.finish()
        libraryEditorRoute = nil
        appTutorialPending = false
        tutorialFollowUpPending = true
    }

    func presentTutorialFollowUpIfNeeded() {
        guard tutorialFollowUpPending, libraryEditorRoute == nil else { return }
        tutorialFollowUpPending = false
        Task { await showPaywallIfNeeded() }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    @Published var refresh = false
    @Published var viewedDate = MyCalendar.getToday()
    @Published var completedEventsShareRequest = UUID()
    @Published var canShareCompletedEvents = false
    // Start compact. Only a tap expands the bar; scrolling can collapse it.
    @Published var planBarExpansion: CGFloat = 0

    func plan(_ event: Event) throws {
        try event.addToPlan()
    }

    func clearPlan() throws {
        try PlanStore.clear(in: Model.viewContext)
    }

    func removeFromPlan(_ event: Event) throws {
        try event.removeFromPlan()
    }

    @Published var currentTab: TabBarItem = TabBarItem.quick
    @Published var showQuickFinishSearch = false
    @Published var showQuickFinishEditor = false
    @Published var showEventHideControls = false
    @Published var expandAllCategoriesRequest = UUID()
    @Published var quickFinishSearchText = ""
    @Published var libraryEditorRoute: LibraryEditorRoute?
    @Published var showChangeEvent = false
    @Published var changeEvent: Event? = nil

    // Onboarding and subscription
    @Published var isShowPaywall = false
    
    @Published private(set) var premiumAccess = PremiumAccessState()
    @Published var subscriptionError: String?
    @Published private(set) var isCheckingSubscription = false

    var isSubscriptionActive: Bool { premiumAccess.hasPremium == true }
    var hasLoadedSubscription: Bool { premiumAccess.hasPremium != nil }

    func updateSubscription(_ customerInfo: CustomerInfo) {
        premiumAccess.update(
            hasPremium: customerInfo.entitlements.all["Premium"]?.isActive == true,
            requestDate: customerInfo.requestDate
        )
    }

    func observeSubscriptionUpdates() async {
        for await customerInfo in Purchases.shared.customerInfoStream {
            guard !Task.isCancelled else { return }
            updateSubscription(customerInfo)
        }
    }

    func refreshSubscriptionStatus() async {
        // The SDK retains CustomerInfo across launches; errors must not revoke it.
        if let customerInfo = try? await Purchases.shared.customerInfo() {
            updateSubscription(customerInfo)
        }
    }

    func checkPremiumAccess() async throws -> Bool {
        do {
            let customerInfo = try await Purchases.shared.customerInfo(
                fetchPolicy: isSubscriptionActive ? .notStaleCachedOrFetched : .fetchCurrent
            )
            updateSubscription(customerInfo)
            return isSubscriptionActive
        } catch {
            // Preserve RevenueCat's cached active access when offline. Unknown/free
            // status needs a successful check before we ask the user to purchase.
            if isSubscriptionActive { return true }
            throw error
        }
    }

    func showPaywallIfNeeded() async {
        guard !isCheckingSubscription else { return }
        isCheckingSubscription = true
        defer { isCheckingSubscription = false }
        do {
            isShowPaywall = try await !checkPremiumAccess()
        } catch {
            subscriptionError = "Unable to verify your subscription. Please try again. \(error.localizedDescription)"
        }
    }
    
    init(){
        if let customerInfo = Purchases.shared.cachedCustomerInfo {
            updateSubscription(customerInfo)
        }
    }
}
