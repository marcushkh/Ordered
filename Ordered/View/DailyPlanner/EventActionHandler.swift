//
//  EventActionHandler.swift
//  Ordered
//
//  Created by Kai Hin Hung on 25/1/2025.
//

import SwiftUI

/// The single event action supported by Ordered.
final class EventActionHandler: ObservableObject {
    static let shared = EventActionHandler()

    private init() {}

    /// Create a fresh occurrence on every call, including repeated calls for the same event.
    func quickFinish(_ event: Event, on date: Date, removingFromPlan: Bool = false) throws {
        let cal = Cal.getOrCreate(date: date)
        let lastFinishedEvent = cal.getLastFinishedEvent()
        let newEvent = event.getEC()

        let items = cal.orderedEvents
        let index = lastFinishedEvent.flatMap { items.firstIndex(of: $0) }.map { $0 + 1 } ?? 0
        var updated = items
        updated.insert(newEvent, at: index)
        cal.event_cals = NSOrderedSet(array: updated)

        // Completion and plan removal must reach disk in the same transaction.
        let previousPlanOrder = event.planOrder
        if removingFromPlan { event.planOrder = -1 }
        do {
            try tickAndSave(ec: newEvent)
        } catch {
            event.planOrder = previousPlanOrder
            Model.viewContext.delete(newEvent)
            throw error
        }
    }

    private func tickAndSave(ec: Event_Cal) throws {
        guard ec.aEndTime == nil else { return }

        HapticFeedback.heavy()
        let tickTime = Date.now.getHHMM()
        ec.startTime = nil
        ec.endTime = nil
        ec.duration = -1
        ec.durationFinished = 0
        ec.aStartTime = tickTime
        ec.aEndTime = tickTime

        try Model.viewContext.save()
    }
}
