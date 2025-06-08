//
//  K.swift
//  Ordered
//
//  Created by Kai Hin Hung on 1/8/2024.
//

import Foundation
import SwiftUI


enum K{
    private static let baseScreenWidth: CGFloat = 375.0 // iPhone 11/12/13/14/15
    
    private static var scaleFactor: CGFloat {
        UIScreen.main.bounds.width / baseScreenWidth
    }
    
    static var horizontal_padding: CGFloat { 20.0 * scaleFactor }
    static var vertical_padding: CGFloat { 16.0 * scaleFactor }
    
    static var xxxsmall_size: CGFloat { 8.0 * scaleFactor }
    static var xxsmall_size: CGFloat { 16.0 * scaleFactor }
    static var xsmall_size: CGFloat  { 20.0 * scaleFactor }
    static var small_size: CGFloat   { 24.0 * scaleFactor }
    static var medium_size: CGFloat  { 28.0 * scaleFactor }
    static var large_size: CGFloat   { 32.0 * scaleFactor }
    static var xlarge_size: CGFloat  { 36.0 * scaleFactor }
    static var xxl_size: CGFloat     { 40.0 * scaleFactor }
    
    static let defaultSectionColor = [
        "DCEDFA",
        "E3BCB5",
        "F0DCB8",
        "D2CAF3",
        "FDFBCC",
        "E6EEDA"
    ]
    
    static let defaultSectionColorDark = [
        "88C0ED",
        "C4819B",
        "D69569",
        "7854EC",
        "C1BC63",
        "819A59"
    ]
    
    static let defaultSection = ["Morning Routine", "Schedule", "Personal Time", "Night Routine"]
    
    static let presentationCornerRadius: CGFloat = 30
}
//Pixels: 24
