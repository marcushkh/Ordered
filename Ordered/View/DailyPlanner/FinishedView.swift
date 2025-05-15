//Cursor GENERATED


import SwiftUI

struct FinishedView: View {
    @ObservedObject var viewModel: ContentViewModel
    
    // Start and end hours (24-hour format)
    let startHour: Int
    let endHour: Int
    
    // Colors for customization
    let lineColor: Color
    let textColor: Color
    
    // Layout constants
    private let hourHeight: CGFloat = 60
    private let leftPadding: CGFloat = 50
    private let timeHeight: CGFloat = 20 // Height of time labels
    
    // Calendar data
    var cal: Cal?
    
    // Initialize with default values (9AM to 5PM with system colors)
    init(
        viewModel: ContentViewModel,
        startHour: Int = 9,
        endHour: Int = 17,
        lineColor: Color = Color(UIColor.systemGray5),
        textColor: Color = .primary,
        cal: Cal? = nil
    ) {
        self._viewModel = ObservedObject(wrappedValue: viewModel)
        self.startHour = startHour
        self.endHour = endHour
        self.lineColor = lineColor
        self.textColor = textColor
        self.cal = cal
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background grid with time lines
            VStack(alignment: .leading, spacing: 0) {
                ForEach(startHour..<endHour + 1, id: \.self) { hour in
                    // Time label
                    HStack(alignment: .center, spacing: 0) {
                        Text(formatHour(hour))
                            .font(.caption)
                            .foregroundColor(textColor)
                            .frame(width: leftPadding - 10, alignment: .leading)
                            .padding(.trailing, 5)
                        
                        // Divider line
                        Rectangle()
                            .fill(lineColor)
                            .frame(height: 1)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(height: timeHeight)
                    
                    // Hour space
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: hourHeight)
                }
            }
            
            // Event blocks - positioned absolutely within the ZStack
            ForEach(startedEvents, id: \.self) { event in
                if let startPosition = eventStartPosition(for: event),
                   let endPosition = eventEndPosition(for: event) {
                    let height = endPosition - startPosition
                    
                    // Only show the event if it has a positive height
                    if height > 0 {
                        EventBlockView(
                            viewModel: viewModel,
                            event: event
                        )
                        .frame(height: height)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, leftPadding - 5)
                        .offset(y: startPosition)
                        .onTapGesture {
                            print(height)
                        }
                    }
                }
            }
        }
        .onChange(of: viewModel.refresh, { oldValue, newValue in
            
        })
        .frame(height: totalHeight)
        .padding(.vertical, 5)
    }
    
    // Get all started events from all sections
    private var startedEvents: [Event_Cal] {
        guard let sections = cal?.section_cals?.array as? [Section_Cal] else { return [] }
        
        var events: [Event_Cal] = []
        for section in sections {
            events.append(contentsOf: section.get_started_event_cals())
        }
        
        // Sort events by start time
        return events.sorted { event1, event2 in
            guard let time1 = event1.aStartTime, let time2 = event2.aStartTime else { return false }
            return time1 < time2
        }
    }
    
    // Calculate position for an event based on its start time
    private func eventStartPosition(for event: Event_Cal) -> CGFloat? {
        guard let startTime = event.aStartTime else { return nil }
        
        let date = Date.getDateFromHHMM(startTime)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        
        guard let hour = components.hour, let minute = components.minute else { return nil }
        
        // Ensure the hour is within our display range
        if hour < startHour || hour > endHour {
            return nil
        }
        
        // Calculate position based on hours and minutes
        let hourIndex = hour - startHour
        
        // Position calculation:
        // 1. Start at the top of the first hour (timeHeight)
        // 2. Add the offset for completed hour blocks (hourIndex * (hourHeight + timeHeight))
        // 3. Add the minute offset within the current hour (minute/60 * hourHeight)
        let position = timeHeight + // Start with the first hour's label height
                      CGFloat(hourIndex) * (hourHeight + timeHeight) + // Add completed hour blocks
                      (CGFloat(minute) / 60.0) * hourHeight // Add minute offset within current hour
        
        return position
    }
    
    // Calculate end position for an event based on its end time
    private func eventEndPosition(for event: Event_Cal) -> CGFloat? {
        guard let endTime = event.aEndTime else { 
            // If no end time, use start time + default duration
            guard let startPos = eventStartPosition(for: event) else { return nil }
            return startPos + (45.0 / 60.0 * hourHeight) // 45 minutes default
        }
        
        let date = Date.getDateFromHHMM(endTime)
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        
        guard let hour = components.hour, let minute = components.minute else { return nil }
        
        // Handle special case: If the event ends exactly at an hour with 0 minutes (like 15:00)
        if minute == 0 {
            // For exact hour endings, place exactly at the hour line
            let hourIndex = hour - startHour
            return timeHeight + CGFloat(hourIndex) * (hourHeight + timeHeight)
        }
        
        // Regular calculation (same logic as start position)
        let hourIndex = hour - startHour
        let position = timeHeight + // Start with the first hour's label height
                      CGFloat(hourIndex) * (hourHeight + timeHeight) + // Add completed hour blocks
                      (CGFloat(minute) / 60.0) * hourHeight // Add minute offset within current hour
        
        return position
    }
    
    // Calculate the total height needed for the view
    private var totalHeight: CGFloat {
        // This method needs to be more precise and include any minutes as well
        
        // Calculate the full hours
        let fullHoursHeight = CGFloat(endHour - startHour) * (hourHeight + timeHeight)
        
        // Add height for the first hour label
        let firstHourLabelHeight = timeHeight
        
        // Add height for the last hour's space
        let lastHourHeight = hourHeight + timeHeight
        
        // Return the total required height
        return fullHoursHeight + firstHourLabelHeight + lastHourHeight
    }
    
    // Format hour to 24-hour string
    private func formatHour(_ hour: Int) -> String {
        return "\(hour):00"
    }
}

// View for a single event block
struct EventBlockView: View {
    @ObservedObject var viewModel: ContentViewModel
    let event: Event_Cal
    
    // Calculate the background color from the hex
    private var blockColor: Color {
        let hexColor = event.section_cal?.location?.color ?? "#B87333"
        return Color(hex: hexColor)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Left colored indicator
            Rectangle()
                .fill(.clear)
                .frame(width: 4)
            
            // Event content
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    ECInfo(ec: event, refresh: viewModel.refresh, highlightedEC: $viewModel.highlightedEC, size: .medium, showStartEndTime: false)
                    Spacer()
                }
                Spacer()
            }
            .padding(4)
//            .padding(.top)
        }
        .background(Color(blockColor).opacity(0.5))
        .cornerRadius(20)
        .frame(maxWidth: .infinity)
        .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
    }
}
