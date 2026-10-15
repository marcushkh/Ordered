/// Keeps the Create request pending while its editor presents the upgrade sheet.
struct EventCreationGate {
    static let freeEventLimit = 50

    private enum State { case editing, awaitingPremium, authorized }
    private var state: State = .editing

    mutating func requestCreation(eventCount: Int, hasPremium: Bool) -> Bool {
        guard state == .editing else { return false }
        if hasPremium || eventCount < Self.freeEventLimit { return true }
        state = .awaitingPremium
        return false
    }

    mutating func confirmPremium(_ hasPremium: Bool) {
        guard hasPremium, state == .awaitingPremium else { return }
        state = .authorized
    }

    /// Consume once, after dismissal so saving cannot dismiss the wrong sheet.
    mutating func finishPaywall() -> Bool {
        let shouldCreate = state == .authorized
        state = .editing
        return shouldCreate
    }
}
