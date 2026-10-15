import SwiftUI

// Adapted from the ShowCase sample: anchors track the live controls across pages
// and sheets. Only the hands-on steps allow interaction through the spotlight.
private struct HighlightAnchorKey: PreferenceKey {
    static let defaultValue: [AppTutorial.Step: Anchor<CGRect>] = [:]
    static func reduce(value: inout [AppTutorial.Step: Anchor<CGRect>], nextValue: () -> [AppTutorial.Step: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

extension View {
    func showCase(_ step: AppTutorial.Step, enabled: Bool = true) -> some View {
        transformAnchorPreference(key: HighlightAnchorKey.self, value: .bounds) { anchors, anchor in
            // One control can be used by multiple steps (for example pin/unpin).
            // Merge its anchors instead of replacing earlier step preferences.
            if enabled { anchors[step] = anchor }
        }
    }

    func tutorialShowCase(_ viewModel: ContentViewModel) -> some View {
        modifier(ShowCaseRoot(viewModel: viewModel))
    }
}

private struct SpotlightMask: Shape {
    let hole: CGRect
    func path(in rect: CGRect) -> Path {
        var path = Path(rect)
        path.addRoundedRect(in: hole, cornerSize: CGSize(width: 16, height: 16))
        return path
    }
}

private struct TutorialCardHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ShowCaseRoot: ViewModifier {
    @ObservedObject var viewModel: ContentViewModel
    @State private var cardHeight: CGFloat = 200

    func body(content: Content) -> some View {
        content.overlayPreferenceValue(HighlightAnchorKey.self) { anchors in
            if let step = viewModel.tutorial.step, let anchor = anchors[step] {
                GeometryReader { geometry in
                    let rect = geometry[anchor].insetBy(dx: -4, dy: -4)
                    let width = min(420, max(0, geometry.size.width - 32))
                    let center = cardCenter(for: rect, in: geometry.size, width: width)
                    ZStack {
                        if step.requiresInteraction {
                            SpotlightMask(hole: rect)
                                .fill(.clear)
                                .contentShape(SpotlightMask(hole: rect), eoFill: true)
                                .onTapGesture { }
                        } else {
                            Rectangle()
                                .fill(.clear)
                                .contentShape(Rectangle())
                                .onTapGesture { advanceExplanation(step) }
                        }
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white, lineWidth: 2)
                            .frame(width: rect.width, height: rect.height)
                            .position(x: rect.midX, y: rect.midY)
                            .allowsHitTesting(false)
                        tutorialCard(step)
                            .frame(width: width)
                            .fixedSize(horizontal: false, vertical: true)
                            .background {
                                GeometryReader { cardGeometry in
                                    Color.clear.preference(key: TutorialCardHeightKey.self,
                                                           value: cardGeometry.size.height)
                                }
                            }
                            .position(center)
                            .onPreferenceChange(TutorialCardHeightKey.self) { height in
                                if height > 0 { cardHeight = height }
                            }
                    }
                    .background {
                        GeometryReader { backdrop in
                            SpotlightMask(hole: backdrop[anchor].insetBy(dx: -4, dy: -4))
                                .fill(.black.opacity(0.6), style: FillStyle(eoFill: true))
                        }
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                    }
                }
            }
        }
    }

    private func tutorialCard(_ step: AppTutorial.Step) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(step.title).font(.headline)
            Text(step.message).font(.subheadline)

        }
        .foregroundStyle(.primary)
        .padding(18)
        .frame(maxWidth: 420, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .contentShape(RoundedRectangle(cornerRadius: 20))
        .onTapGesture { advanceExplanation(step) }
        .accessibilityElement(children: .contain)
        .accessibilityAction(named: step == .statistics ? "Finish tutorial" : "Continue tutorial") {
            advanceExplanation(step)
        }
    }

    private func advanceExplanation(_ step: AppTutorial.Step) {
        guard !step.requiresInteraction, viewModel.tutorial.step == step else { return }
        if step == .statistics {
            viewModel.finishTutorial()
        } else {
            viewModel.nextTutorialStep()
        }
    }

    private func cardCenter(for highlight: CGRect, in size: CGSize, width: CGFloat) -> CGPoint {
        let margin: CGFloat = 16
        let gap: CGFloat = 12
        let below = size.height - margin - highlight.maxY - gap
        let above = highlight.minY - gap - margin
        let top: CGFloat
        if below >= cardHeight {
            top = highlight.maxY + gap
        } else if above >= cardHeight {
            top = highlight.minY - gap - cardHeight
        } else {
            // Large highlights may leave no room outside them; keep the card on screen.
            let preferred = below >= above ? highlight.maxY + gap : highlight.minY - gap - cardHeight
            top = min(max(margin, preferred), max(margin, size.height - margin - cardHeight))
        }
        let x = min(max(margin + width / 2, highlight.midX), size.width - margin - width / 2)
        return CGPoint(x: x, y: top + cardHeight / 2)
    }
}
