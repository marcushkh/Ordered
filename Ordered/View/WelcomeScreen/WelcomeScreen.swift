import SwiftUI

struct WelcomeScreen: View {
    @ObservedObject var viewModel: ContentViewModel
    @StateObject private var welcomeVM = WelcomeVM()
    @Environment(\.managedObjectContext) private var context
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingPrivacy = false
    @AppStorage("welcomeScreen") private var welcomeScreen = true

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: goBack) {
                    Label("Back", systemImage: "chevron.left")
                        .font(.body.weight(.semibold))
                        .frame(minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!showingPrivacy && welcomeVM.categoryIndex == 0)
                Spacer()
            }
            .padding(.bottom, 8)


            if showingPrivacy {
                Privacy()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                Button(action: startTutorial) {
                    HStack {
                        Spacer()
                        Text("Show Me Around")
                        Image(systemName: "arrow.right")
                        Spacer()
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical)
                    .background(Color(hex: "484B6A"), in: RoundedRectangle(cornerRadius: 20))
                }
                .buttonStyle(.plain)
            } else {
                CategoryOnboarding(welcomeVM: welcomeVM) {
                    withAnimation(.easeInOut(duration: 0.25)) { showingPrivacy = true }
                }
            }
        }
        .padding(.horizontal, K.horizontal_padding)
        .padding(.vertical, 16)
        .background(Color.cBackground.ignoresSafeArea())
        .alert(welcomeVM.alertMessage, isPresented: $welcomeVM.showAlert) {
            Button("OK", role: .cancel) { }
        }
    }

    private func goBack() {
        withAnimation(.easeInOut(duration: 0.25)) {
            welcomeVM.previousCategory()
            showingPrivacy = false
        }
        HapticFeedback.light()
    }

    private func startTutorial() {
        do {
            try welcomeVM.saveCategories(in: context, colorScheme: colorScheme)
            viewModel.refresh.toggle()
            viewModel.appTutorialPending = true
            withAnimation { welcomeScreen = false }
            HapticFeedback.heavy()
        } catch {
            welcomeVM.alertMessage = "Couldn’t save your setup. Please try again. \(error.localizedDescription)"
            welcomeVM.showAlert = true
        }
    }
}
