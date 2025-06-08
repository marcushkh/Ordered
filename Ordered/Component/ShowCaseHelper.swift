//
//  ShowCaseHelper.swift
//  Ordered
//
//  Created by Kai Hin Hung on 24/5/2025.
//
import SwiftUI

extension View{
    @ViewBuilder
    func showCase(order: Int, title: String, cornerRadius: CGFloat, style: RoundedCornerStyle = .continuous, scale: CGFloat = 1, onComplete: (() -> Void)? = nil) -> some View{
        self
            .anchorPreference(key: HighlightAnchorKey.self, value: .bounds) { anchor in
                let highlight = Highlight(anchor: anchor, title: title, cornerRadius: cornerRadius, style: style, scale: scale, onComplete: onComplete)
                return [order: highlight]
            }
    }
    
    @ViewBuilder
    func reverseMask<Content: View>(alignment: Alignment = .topLeading, @ViewBuilder content: @escaping () -> Content) -> some View{
        self
            .mask{
                Rectangle()
                    .overlay(alignment: .topLeading){
                        content()
                            .blendMode(.destinationOut)
                    }
            }
    }
}

// ShowCase Root View Modifier
struct ShowCaseRoot: ViewModifier{
    var showHighlights: Bool
    var onFinished: () -> ()
    
    @State private var highlightOrder: [Int] = []
    @State private var currentHighlight: Int = 0
    @State private var showView: Bool = true
    @State private var showTitle: Bool = false
    
    func body(content: Content) -> some View {
        content
            .onPreferenceChange(HighlightAnchorKey.self){ value in
//                highlightOrder = Array(value.keys).sorted()
                let newKeys = Array(value.keys)
                let existingKeys = Set(highlightOrder)
                let allKeys = Set(newKeys).union(existingKeys)
                highlightOrder = Array(allKeys).sorted()
            }
            .overlayPreferenceValue(HighlightAnchorKey.self) { preferences in
                if highlightOrder.indices.contains(currentHighlight), showHighlights, showView{
                    if let highlight = preferences[highlightOrder[currentHighlight]] {
                        HighlightView(highlight, preferences: preferences, highlightOrder: highlightOrder)
                    }
                }
            }
            .onChange(of: currentHighlight) { oldValue, newValue in
                print("CURRENT HIGHLIGHT IS " + String(currentHighlight))
                print(highlightOrder)
            }
    }
    
    @ViewBuilder
    func HighlightView(_ highlight: Highlight, preferences: [Int: Highlight], highlightOrder: [Int]) -> some View{
        GeometryReader{ geo in
            let highlightRect = geo[highlight.anchor]
            let safeArea = geo.safeAreaInsets
            
            Rectangle()
                .fill(.cPrimary.opacity(0.5))
                .reverseMask(content: {
                    Rectangle()
                        .frame(width: highlightRect.width + 5, height: highlightRect.height + 5)
                        .clipShape(RoundedRectangle(cornerRadius: highlight.cornerRadius, style: highlight.style))
                        .scaleEffect(highlight.scale)
                        .offset(x: highlightRect.minX - 2.5, y: highlightRect.minY - 2.5 + safeArea.top)
                })
                .ignoresSafeArea()
                .onAppear{
                    showTitle = true
                }
                .onTapGesture {
                    // Execute the completion handler for the current highlight
                    highlight.onComplete?()
                    
                    if currentHighlight >= highlightOrder.count - 1{
                        withAnimation {
                            showView = false
                        }
                        onFinished()
                    }
                    else{
                        withAnimation (.interactiveSpring(response: 0.1, dampingFraction: 0.7, blendDuration: 0.2)) {
                            showTitle = false
                            currentHighlight += 1
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4){
                            showTitle = true
                        }
                    }
                }
                .onChange(of: showTitle) { oldValue, newValue in
                    guard !newValue else{return}
                    
                    // Execute the completion handler for the current highlight
                    highlight.onComplete?()
                    
                    if currentHighlight >= highlightOrder.count - 1{
                        withAnimation {
                            showView = false
                        }
                        onFinished()
                    }
                    else{
                        withAnimation (.interactiveSpring(response: 0.3, dampingFraction: 0.7, blendDuration: 0.7)) {
                            showTitle = false
                            currentHighlight += 1
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4){
                            showTitle = true
                        }
                    }
                }
            
            Rectangle()
                .foregroundStyle(.clear)
                .frame(width: highlightRect.width + 20, height: highlightRect.height + 20)
                .clipShape(RoundedRectangle(cornerRadius: highlight.cornerRadius, style: highlight.style))
                .popover(isPresented: $showTitle) {
                    Text(highlight.title)
                        .multilineTextAlignment(.center)
                        .frame(maxHeight: 200)
                        .padding()
                        .presentationCompactAdaptation(.popover)
                }
                .offset(x: highlightRect.minX - 10, y: highlightRect.minY - 10)
        }
    }
}

// Anchor Key
fileprivate struct HighlightAnchorKey: PreferenceKey{
    static var defaultValue: [Int: Highlight] = [:]
    
    static func reduce(value: inout [Int : Highlight], nextValue: () -> [Int : Highlight]) {
        value.merge(nextValue()) { $1 }
    }
}

struct Highlight: Identifiable, Equatable{
    var id: UUID = .init()
    var anchor: Anchor<CGRect>
    var title: String
    var cornerRadius: CGFloat
    var style: RoundedCornerStyle = .continuous
    var scale: CGFloat = 1
    var onComplete: (() -> Void)?
    
    static func == (lhs: Highlight, rhs: Highlight) -> Bool {
        return lhs.id == rhs.id
    }
}
