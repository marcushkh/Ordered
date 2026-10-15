import Foundation

/// Layout preferences reference stable event/category IDs; they never change library data.
struct QuickFinishOrder: Codable, Identifiable {
    var id = UUID()
    var name = "New Order"
    var groupIDs: [String]
    var eventIDs: [String: [String]]
    var hiddenGroupIDs: Set<String>
    var hiddenEventIDs: Set<String>

    func arranged<T>(_ values: [T], ids: [String], identifier: (T) -> String) -> [T] {
        let ranks = Dictionary(ids.enumerated().map { ($0.element, $0.offset) }, uniquingKeysWith: { first, _ in first })
        return values.enumerated().sorted {
            let lhs = ranks[identifier($0.element)] ?? Int.max
            let rhs = ranks[identifier($1.element)] ?? Int.max
            return lhs == rhs ? $0.offset < $1.offset : lhs < rhs
        }.map(\.element)
    }
}

struct QuickFinishOrderSettings: Codable {
    var orders: [QuickFinishOrder] = []
    var selectedID: UUID?

    var selected: QuickFinishOrder? { orders.first { $0.id == selectedID } }

    static let storageKey = "QuickFinishOrders.v1"

    static func load(from defaults: UserDefaults = .standard) -> Self {
        guard let data = defaults.data(forKey: storageKey),
              var settings = try? JSONDecoder().decode(Self.self, from: data) else { return Self() }
        if settings.selected == nil { settings.selectedID = nil }
        return settings
    }

    func save(to defaults: UserDefaults = .standard) {
        if let data = try? JSONEncoder().encode(self) { defaults.set(data, forKey: Self.storageKey) }
    }

    mutating func add(_ snapshot: QuickFinishOrder) {
        var copy = snapshot
        copy.id = UUID()
        copy.name = "New Order"
        orders.append(copy)
        selectedID = copy.id
    }

    mutating func renameSelected(_ name: String) {
        guard let index = orders.firstIndex(where: { $0.id == selectedID }) else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        orders[index].name = trimmed.isEmpty ? "New Order" : trimmed
    }
}
