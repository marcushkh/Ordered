//
//  View+Ext.swift
//  Ordered
//
//  Created by Kai Hin Hung on 28/7/2024.
//

import SwiftUI

extension View {
    //souce !!!!!
    func underlineTextField(underline lineColor: Color, focus: Bool = false, focusColor: Color = .white) -> some View {
        self
            .overlay(Rectangle().frame(height: 2).padding(.top, 35).foregroundStyle(focus ? focusColor : lineColor))
    }
    
    func Background<Content: View>
    (color: Color, opacity: Double = 1, allFocusStates: [FocusState<Bool>.Binding] = [], allBinding: [Binding<Bool>] = [] , content: () -> Content)
    -> some View{
        ZStack{
            Color(color)
                .opacity(opacity)
                .onTapGesture {
                    for i in allFocusStates{
                        i.wrappedValue = false
                    }
                    for j in allBinding{
                        j.wrappedValue = false
                    }
                }
                .ignoresSafeArea()
            
            content()
        }
    }
}
