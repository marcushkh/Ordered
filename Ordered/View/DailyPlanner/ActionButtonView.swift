//
//  ActionButtonView.swift
//  Ordered
//
//  Created by Kai Hin Hung on 25/1/2025.
//

import SwiftUI

struct ActionButtonView: View {
    @ObservedObject var viewModel: ContentViewModel
    @ObservedObject var sc: Section_Cal
    @ObservedObject var ec: Event_Cal
    @ObservedObject private var actionHandler = EventActionHandler.shared

    var body: some View {
        if ec.parent == nil {
            EmptyView()
        } else {
            ZStack {
                Circle()
                    .fill(ec.aEndTime == nil ? Color(.color1) : Color(.success))
                    .frame(height: K.medium_size)

                Image(systemName: "checkmark")
            }
            .contentShape(Circle())
            .onTapGesture {
                guard ec.aEndTime == nil else { return }
                withAnimation {
                    actionHandler.tick(ec: ec)
                    viewModel.refresh.toggle()
                }
            }
        }
    }
}
