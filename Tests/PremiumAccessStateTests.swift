import Foundation

@main
struct PremiumAccessStateTests {
    static func main() {
        var state = PremiumAccessState()
        precondition(state.hasPremium == nil)
        let cachedDate = Date(timeIntervalSince1970: 100)
        let purchaseDate = Date(timeIntervalSince1970: 200)
        let expirationDate = Date(timeIntervalSince1970: 300)
        state.update(hasPremium: true, requestDate: cachedDate)
        precondition(state.hasPremium == true)
        state.update(hasPremium: true, requestDate: purchaseDate)
        state.update(hasPremium: false, requestDate: cachedDate)
        precondition(state.hasPremium == true) // Late launch response cannot undo purchase.
        state.update(hasPremium: false, requestDate: expirationDate)
        precondition(state.hasPremium == false) // Confirmed expiry must lock access.
        state.update(hasPremium: true, requestDate: purchaseDate)
        precondition(state.hasPremium == false) // Stale active data cannot undo expiry.
        state.update(hasPremium: true, requestDate: expirationDate.addingTimeInterval(1))
        precondition(state.hasPremium == true)
        print("PASS: unknown initial status, cached access, stale responses, expiry, and renewal")
    }
}
