import SwiftUI

struct Privacy: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                HStack{
                    Spacer()
                    Image("Privacy")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 300, height: 300)
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("All Data are Secure")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    Text("We do not collect any data from you. All data are saved in device or user can opt-in for iCloud backup.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 40)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }
}
