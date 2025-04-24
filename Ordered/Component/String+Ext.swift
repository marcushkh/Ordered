//
//  String+Ext.swift
//  Ordered
//
//  Created by Kai Hin Hung on 27/2/2025.
//
import SwiftUI

extension String{
    func HHmmssPresentation() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        
        if let date = dateFormatter.date(from: self) {
            dateFormatter.dateFormat = "HH:mm"
            return dateFormatter.string(from: date)
        }
        return self
    }
    var capitalizedFirst: String {
        return prefix(1).uppercased() + dropFirst()
    }
}
