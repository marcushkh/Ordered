import CoreData

extension Cal {
    var orderedEvents: [Event_Cal] { event_cals?.array as? [Event_Cal] ?? [] }

    static func get(date: String) -> Cal? {
        let request: NSFetchRequest<Cal> = Cal.fetchRequest()
        request.predicate = NSPredicate(format: "date == %@", date)
        request.fetchLimit = 1
        return try? Model.viewContext.fetch(request).first
    }

    static func get(date: Date) -> Cal? { get(date: date.getYYMMDD()) }

    static func new(date: String) -> Cal {
        let calendar = Cal(context: Model.viewContext)
        calendar.date = date
        calendar.event_cals = NSOrderedSet()
        return calendar
    }

    static func new(date: Date) -> Cal { new(date: date.getYYMMDD()) }

    static func getOrCreate(date: Date) -> Cal { get(date: date) ?? new(date: date) }

    func getLastFinishedEvent() -> Event_Cal? {
        orderedEvents.last { ($0.parent != nil || $0.isOneTime) && $0.aEndTime != nil }
    }

}
