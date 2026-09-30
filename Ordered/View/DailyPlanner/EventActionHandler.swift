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

    /// Create a fresh occurrence on every call, including repeated calls for the same event.
    func quickFinish(_ event: Event, on date: Date) throws {
        let cal = Cal.getOrCreate(date: date)
        let lastFinishedEvent = cal.getLastFinishedEvent()
        let newEvent = event.getEC()

        if let destination = event.quickFinishSection, destination.isActive {
            let sections = cal.section_cals?.array as? [Section_Cal] ?? []
            // Prefer the latest occurrence if this section appears more than once.
            let section = sections.last(where: { $0.parent == destination }) ?? {
                let section = Section_Cal.new()
                section.parent = destination
                cal.addSection(section)
                return section
            }()
            section.add(event: newEvent)
        }
        else if let lastFinishedEvent,
           let section = lastFinishedEvent.section_cal {
            section.insert(newEvent, after: lastFinishedEvent)
        }
        else if let section = cal.section_cals?.firstObject as? Section_Cal {
            section.add(event: newEvent)
        }
        else {
            let section = Section_Cal.new()
            section.add(event: newEvent)
            cal.addSection(section)
        }

        try tickAndSave(ec: newEvent)
    }

    func tick(ec: Event_Cal) {
        do {
            try tickAndSave(ec: ec)
        } catch {
            print("Failed to tick event: \(error.localizedDescription)")
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
