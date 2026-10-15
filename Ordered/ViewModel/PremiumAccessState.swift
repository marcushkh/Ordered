import Foundation

/// Unknown status is distinct from a confirmed free account. Failed requests do not update it.
struct PremiumAccessState {
    private(set) var hasPremium: Bool?
    private(set) var requestDate: Date?

    mutating func update(hasPremium: Bool, requestDate: Date) {
        if let currentDate = self.requestDate, requestDate < currentDate { return }
        self.hasPremium = hasPremium
        self.requestDate = requestDate
    }
}
