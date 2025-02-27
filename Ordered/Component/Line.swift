//
//  Line.swift
//  Ordered
//
//  Created by Kai Hin Hung on 27/2/2025.
//

import SwiftUI

// Source https://stackoverflow.com/questions/58526632/swiftui-create-a-single-dashed-line-with-swiftui
struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        return path
    }
}
