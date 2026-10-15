import SwiftUI
import CoreData
import Lottie

/// Hold layout before persistence changes; start playback only after a successful save.
@MainActor
final class EventCompletionCelebrations: ObservableObject {
    struct Playback: Equatable {
        let id = UUID()
        let startedAt = Date()
    }

    static let shared = EventCompletionCelebrations()
    static let duration: TimeInterval = 1.5
    // The bundled Lottie burst marker is frame 60 at 120 fps.
    static let burstDelay: TimeInterval = 0.5
    @Published private(set) var active: [NSManagedObjectID: Playback] = [:]

    @Published private(set) var activeDrafts: [UUID: Playback] = [:]

    @Published private var preparing: [NSManagedObjectID: UUID] = [:]

    /// Core Data can notify views during save, before playback has been registered.
    /// Reserve the layout first so a completed category never briefly jumps to a pill.
    func prepareCompletion(eventID: NSManagedObjectID) -> UUID? {
        guard !UIAccessibility.isReduceMotionEnabled else { return nil }
        let token = UUID()
        preparing[eventID] = token
        return token
    }

    func endPreparation(eventID: NSManagedObjectID, token: UUID?) {
        guard let token, preparing[eventID] == token else { return }
        preparing[eventID] = nil
    }

    func holdsCategoryOpen(eventID: NSManagedObjectID) -> Bool {
        preparing[eventID] != nil || active[eventID] != nil
    }

    func celebrate(eventID: NSManagedObjectID, completionID: NSManagedObjectID) {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        let playback = Playback()
        let ids = Set([eventID, completionID])
        var next = active
        for id in ids { next[id] = playback }
        active = next
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(Self.burstDelay))
            if self?.active[eventID]?.id == playback.id,
               UIApplication.shared.applicationState == .active {
                HapticFeedback.medium()
            }
            // Home cards briefly show their emoji again; plan cards remove themselves
            // from the playback completion callback, without waiting for this cleanup.
            try? await Task.sleep(for: .seconds(Self.duration + 0.3 - Self.burstDelay))
            guard let self else { return }
            var remaining = self.active
            for id in ids where remaining[id]?.id == playback.id {
                remaining[id] = nil
            }
            self.active = remaining
        }
    }

    /// Onboarding uses draft identities because its events have not been persisted yet.
    func celebrate(draftID: UUID) {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        let playback = Playback()
        activeDrafts[draftID] = playback
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(Self.burstDelay))
            if self?.activeDrafts[draftID]?.id == playback.id,
               UIApplication.shared.applicationState == .active {
                HapticFeedback.medium()
            }
            try? await Task.sleep(for: .seconds(Self.duration + 0.3 - Self.burstDelay))
            guard self?.activeDrafts[draftID]?.id == playback.id else { return }
            self?.activeDrafts[draftID] = nil
        }
    }

    func cancel(draftID: UUID) {
        activeDrafts[draftID] = nil
    }

}

/// Keeps layout and accessibility stable while replacing only the event's emoji.
struct EventCompletionIcon: View {
    let icon: String
    let eventID: NSManagedObjectID?
    let fontSize: CGFloat
    var draftID: UUID? = nil
    var hidesEmojiAfterCompletion = false
    var onPlaybackFinished: (() -> Void)? = nil
    @ObservedObject private var celebrations = EventCompletionCelebrations.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var finishedPlaybackID: UUID?

    private var playback: EventCompletionCelebrations.Playback? {
        let candidate = eventID.flatMap { celebrations.active[$0] }
            ?? draftID.flatMap { celebrations.activeDrafts[$0] }
        guard !reduceMotion,
              let playback = candidate,
              playback.id != finishedPlaybackID,
              (hidesEmojiAfterCompletion || Date().timeIntervalSince(playback.startedAt) < EventCompletionCelebrations.duration) else { return nil }
        return playback
    }

    var body: some View {
        Text(icon)
            .font(.system(size: fontSize))
            .opacity(playback == nil && !hidesEmojiAfterCompletion ? 1 : 0)
            .overlay {
                if let playback {
                    CompletionLottieView(playback: playback) {
                        finishedPlaybackID = playback.id
                        onPlaybackFinished?()
                    }
                    // The composition includes room for the paper's flight; keep its cone
                    // centered on the emoji while allowing the burst to overflow the circle.
                    .frame(width: fontSize * 2.3, height: fontSize * 2.3)
                    .offset(x: fontSize * 0.2, y: -fontSize * 0.09)
                    .id(playback.id)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                }
            }
            .accessibilityLabel(icon)
            .transaction { $0.animation = nil }
    }
}

private struct CompletionLottieView: UIViewRepresentable {
    let playback: EventCompletionCelebrations.Playback
    let onFinished: () -> Void
    private static let animation = LottieAnimation.named("party-popper")

    func makeUIView(context: Context) -> LottieAnimationView {
        let view = LottieAnimationView(
            animation: Self.animation,
            configuration: LottieConfiguration(renderingEngine: .mainThread)
        )
        view.contentMode = .scaleAspectFit
        view.backgroundBehavior = .stop
        view.isUserInteractionEnabled = false
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        guard Self.animation != nil else {
            DispatchQueue.main.async(execute: onFinished)
            return view
        }
        let progress = min(1, max(0, Date().timeIntervalSince(playback.startedAt) / EventCompletionCelebrations.duration))
        view.play(fromProgress: progress, toProgress: 1, loopMode: .playOnce) { finished in
            guard finished else { return }
            DispatchQueue.main.async(execute: onFinished)
        }
        return view
    }

    func updateUIView(_ uiView: LottieAnimationView, context: Context) {}

    static func dismantleUIView(_ uiView: LottieAnimationView, coordinator: ()) {
        uiView.stop()
    }
}
