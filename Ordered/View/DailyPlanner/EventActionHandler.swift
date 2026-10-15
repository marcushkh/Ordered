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

    /// Every completion clears this event from the plan, regardless of its entry point.
    /// Repeated completions still create separate occurrences.
    @MainActor
    @discardableResult
    func quickFinish(_ event: Event, on date: Date) throws -> Event_Cal {
        let celebrations = EventCompletionCelebrations.shared
        let preparation = celebrations.prepareCompletion(eventID: event.objectID)
        defer { celebrations.endPreparation(eventID: event.objectID, token: preparation) }
        HapticFeedback.soft()
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
        event.planOrder = -1
        do {
            try tickAndSave(ec: newEvent)
            celebrations.celebrate(eventID: event.objectID, completionID: newEvent.objectID)
            return newEvent
        } catch {
            event.planOrder = previousPlanOrder
            Model.viewContext.delete(newEvent)
            throw error
        }
    }

    private func tickAndSave(ec: Event_Cal) throws {
        guard ec.aEndTime == nil else { return }

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
