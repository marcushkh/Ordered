//
//  SwipeableStack.swift
//  Ordered
//
//  Created by Kai Hin Hung on 15/8/2024.
//

import SwiftUI

struct SwipeableStack<Data: Hashable, Content: View>: View {
    let data: [Data]
    let jumpTo: Data?
    let onPageChanged: (Data) -> Void
    let content: (Data, ViewPosition) -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var currentData: Data?
    @State private var dragOffset: CGFloat = 0
    @State private var isSettling = false
    @State private var isDragging = false
    @State private var animationID = UUID()

    init(_ data: [Data], jumpTo: Data? = nil,
         onPageChanged: @escaping (Data) -> Void = { _ in },
         @ViewBuilder content: @escaping (Data, ViewPosition) -> Content) {
        self.data = data
        self.jumpTo = jumpTo
        self.onPageChanged = onPageChanged
        self.content = content
        _currentData = State(initialValue: jumpTo ?? data.first)
    }

    private var currentIndex: Int? {
        guard let currentData else { return data.isEmpty ? nil : 0 }
        return data.firstIndex(of: currentData)
    }

    var body: some View {
        GeometryReader { geometry in
            let distance = geometry.size.width + K.horizontal_padding * 2
            ZStack {
                if let index = currentIndex {
                    ForEach(-1...1, id: \.self) { offset in
                        let pageIndex = index + offset
                        if data.indices.contains(pageIndex) {
                            content(data[pageIndex], position(for: offset))
                                .allowsHitTesting(!isDragging && !isSettling)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                                .offset(x: CGFloat(offset) * distance + dragOffset)
                                .accessibilityHidden(offset != 0)
                        }
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .contentShape(Rectangle())
            .highPriorityGesture(
                DragGesture(minimumDistance: 15)
                    .onChanged { value in
                        guard !isSettling, let index = currentIndex,
                              abs(value.translation.width) > abs(value.translation.height) else { return }
                        isDragging = true
                        let atEdge = (value.translation.width > 0 && index == 0)
                            || (value.translation.width < 0 && index == data.count - 1)
                        dragOffset = value.translation.width * (atEdge ? 0.25 : 1)
                    }
                    .onEnded { value in
                        isDragging = false
                        guard !isSettling, let index = currentIndex else { return }
                        let horizontal = abs(value.translation.width) > abs(value.translation.height)
                        let projected = value.predictedEndTranslation.width
                        var targetIndex = index
                        if horizontal && (value.translation.width < -geometry.size.width * 0.25 || projected < -geometry.size.width * 0.5) {
                            targetIndex = min(index + 1, data.count - 1)
                        } else if horizontal && (value.translation.width > geometry.size.width * 0.25 || projected > geometry.size.width * 0.5) {
                            targetIndex = max(index - 1, 0)
                        }
                        settle(from: index, to: targetIndex, distance: distance)
                    }
            )
        }
        .clipped()
        .onChange(of: jumpTo) { _, value in synchronize(to: value) }
        .onChange(of: data) { _, values in
            if let currentData, values.contains(currentData) { return }
            synchronize(to: jumpTo ?? values.first)
        }
    }

    private func position(for offset: Int) -> ViewPosition {
        switch offset {
        case -1: return .previousView
        case 1: return .nextView
        default: return .centerView
        }
    }

    private func synchronize(to value: Data?) {
        guard let value, data.contains(value), value != currentData else { return }
        animationID = UUID()
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            currentData = value
            dragOffset = 0
            isSettling = false
            isDragging = false
        }
    }

    private func settle(from index: Int, to targetIndex: Int, distance: CGFloat) {
        let target = data[targetIndex]
        let token = UUID()
        animationID = token
        isSettling = true
        let finish = {
            guard animationID == token else { return }
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                currentData = target
                dragOffset = 0
                isSettling = false
                if targetIndex != index { onPageChanged(target) }
            }
        }
        if reduceMotion {
            finish()
        } else {
            withAnimation(.smooth(duration: 0.3), completionCriteria: .removed) {
                dragOffset = -CGFloat(targetIndex - index) * distance
            } completion: {
                finish()
            }
        }
    }
}

enum ViewPosition {
    case centerView
    case previousView
    case nextView
}
