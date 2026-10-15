import Foundation

@main
struct QuickFinishOrderTests {
    static func main() throws {
        let suite = "Ordered.QuickFinishOrderTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let allEvents = QuickFinishOrder(groupIDs: ["work", "personal"],
            eventIDs: ["work": ["email", "meeting"], "personal": ["read"]],
            hiddenGroupIDs: ["personal"], hiddenEventIDs: ["meeting"])
        var settings = QuickFinishOrderSettings.load(from: defaults)
        precondition(settings.selected == nil && settings.orders.isEmpty)
        settings.add(allEvents)
        let firstID = settings.selectedID
        precondition(settings.selected?.name == "New Order")
        precondition(settings.selected?.eventIDs == allEvents.eventIDs)
        precondition(settings.selected?.hiddenGroupIDs == allEvents.hiddenGroupIDs)
        precondition(settings.selected?.hiddenEventIDs == allEvents.hiddenEventIDs)
        settings.renameSelected("  Morning  ")
        settings.orders[0].groupIDs.reverse()
        settings.orders[0].eventIDs["work"] = ["meeting", "email"]
        settings.orders[0].hiddenEventIDs = ["email"]
        settings.add(allEvents)
        precondition(settings.selectedID != firstID)
        precondition(settings.selected?.eventIDs["work"] == ["email", "meeting"])
        precondition(settings.orders[0].name == "Morning")
        precondition(settings.orders[0].hiddenEventIDs == ["email"])
        settings.renameSelected(" \n ")
        precondition(settings.selected?.name == "New Order")
        settings.save(to: defaults)
        let restored = QuickFinishOrderSettings.load(from: defaults)
        precondition(restored.selectedID == settings.selectedID && restored.orders.count == 2)
        precondition(restored.orders[0].eventIDs["work"] == ["meeting", "email"])
        precondition(restored.orders[0].hiddenEventIDs == ["email"])
        // Removed IDs are ignored; newly created events retain their library order at the end.
        let arranged = restored.orders[0].arranged(["email", "new-a", "new-b"],
            ids: ["removed", "meeting", "email"], identifier: { $0 })
        precondition(arranged == ["email", "new-a", "new-b"])
        settings.selectedID = nil
        settings.save(to: defaults)
        precondition(QuickFinishOrderSettings.load(from: defaults).selected == nil)
        settings.selectedID = UUID()
        settings.save(to: defaults)
        precondition(QuickFinishOrderSettings.load(from: defaults).selectedID == nil)
        print("PASS: independent copies, visibility, rename, saved selection, reload, and library changes")
    }
}
