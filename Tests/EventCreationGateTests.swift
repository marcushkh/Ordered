@main
struct EventCreationGateTests {
    static func main() {
        var gate = EventCreationGate()
        precondition(gate.requestCreation(eventCount: 49, hasPremium: false))
        precondition(gate.requestCreation(eventCount: 50, hasPremium: true))
        precondition(!gate.requestCreation(eventCount: 50, hasPremium: false))
        gate.confirmPremium(true)
        gate.confirmPremium(true) // Duplicate purchase/restore notifications.
        precondition(gate.finishPaywall())
        precondition(!gate.finishPaywall()) // Never create twice.

        // Cancellation, failure, and restoring without Premium must not create.
        for _ in 0..<3 {
            precondition(!gate.requestCreation(eventCount: 51, hasPremium: false))
            gate.confirmPremium(false)
            precondition(!gate.finishPaywall())
        }

        // A late callback after cancellation must not authorize a future draft.
        gate.confirmPremium(true)
        precondition(!gate.finishPaywall())
        precondition(!gate.requestCreation(eventCount: 51, hasPremium: false))
        precondition(!gate.finishPaywall())

        // Retry succeeds; a restored Premium entitlement follows this same path.
        precondition(!gate.requestCreation(eventCount: 51, hasPremium: false))
        gate.confirmPremium(false) // A failed attempt can be followed by success.
        gate.confirmPremium(true)
        precondition(gate.finishPaywall())
        // If the database save then fails, Premium allows a normal retry.
        precondition(gate.requestCreation(eventCount: 51, hasPremium: true))
        print("PASS: free limit, Premium bypass, purchase/restore continuation, cancellation, retry, and exactly-once continuation")
    }
}
