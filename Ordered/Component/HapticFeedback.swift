//
//  HapticFeedback.swift
//  Ordered
//
//  Created by Kai Hin Hung on 14/6/2025.
//

import UIKit

struct HapticFeedback {
    // MARK: - Haptic Feedback Helper
    static func triggerHapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard UIDevice.current.userInterfaceIdiom == .phone else { return }
        
        let impactFeedback = UIImpactFeedbackGenerator(style: style)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
    }
    
    static func soft() {
        triggerHapticFeedback(style: .soft)
    }

    static func light() {
        triggerHapticFeedback(style: .light)
    }
    
    static func medium() {
        triggerHapticFeedback(style: .medium)
    }
    
    static func heavy() {
        triggerHapticFeedback(style: .heavy)
    }
}
