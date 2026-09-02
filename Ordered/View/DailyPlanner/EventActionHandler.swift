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

    // Retained as read-only compatibility state for the existing Live Activity
    // content model. Tick events never start a timer.
    @Published private(set) var timePassed: Double = 0
    @Published private(set) var startTime: Date? = nil
    @Published private(set) var currentECID: String? = nil

    private init() {}

    func tick(ec: Event_Cal) {
        guard ec.aEndTime == nil else { return }

        HapticFeedback.heavy()
        let tickTime = Date.now.getHHMM()
        ec.startTime = nil
        ec.endTime = nil
        ec.duration = -1
        ec.durationFinished = 0
        ec.aStartTime = tickTime
        ec.aEndTime = tickTime

        do {
            try Model.viewContext.save()
        } catch {
            print("Failed to tick event: \(error.localizedDescription)")
        }

        LiveActivityActions.refreshLiveActivities()
    }

    func isCurrentEC(ec: Event_Cal) -> Bool { false }
    func getCurrentTimePassed() -> String { "0:00" }

    // Compatibility for Live Activities created by an older app version. These
    // actions can no longer start, pause, resume, or accumulate a duration.
    func start(ec: Event_Cal) { tick(ec: ec) }
    func pause(ec: Event_Cal) {}
    func resume(ec: Event_Cal) { tick(ec: ec) }
    func end(ec: Event_Cal, customEndTime: String? = nil) { tick(ec: ec) }
    func AddCurrentTimePassed(min: Int) {}
    func reset() {}
}
