import SwiftUI

struct FinishedView: View {
    // Start and end hours (24-hour format)
    let startHour: Int
    let endHour: Int
    
    // Colors for customization
    let lineColor: Color
    let textColor: Color
    
    // Initialize with default values (9AM to 5PM with system colors)
    init(
        startHour: Int = 9, 
        endHour: Int = 17,
        lineColor: Color = Color(UIColor.systemGray5),
        textColor: Color = .primary
    ) {
        self.startHour = startHour
        self.endHour = endHour
        self.lineColor = lineColor
        self.textColor = textColor
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            ForEach(startHour..<endHour + 1, id: \.self) { hour in
                    // Time label
                HStack(alignment: .center) {
                    
                    Text(formatHour(hour))
                        .font(.caption)
                        .foregroundColor(textColor)
                    
                    VStack{
                        // Divider line
                        Rectangle()
                            .fill(lineColor)
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                        
                    }
                }
                .padding(.horizontal)
                
                Rectangle()
                    .fill(Color.clear)
                    .frame(height: 60)
            }
        }
        .padding(.vertical)
    }
    
    // Format hour to 24-hour string
    private func formatHour(_ hour: Int) -> String {
        return "\(hour):00"
    }
}
