import SwiftUI

struct SectionInfo: View {
    @ObservedObject var section: Section

    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(Color(hex: section.color ?? K.defaultSectionColor[0]))
                    .frame(height: K.xlarge_size)
                Text(section.icon ?? "📁")
                    .font(.title3)
            }
            .padding(.trailing, 8)

            Text(section.name ?? "Section")
                .font(.title3)
                .lineLimit(1)
            Spacer()
        }
    }
}
