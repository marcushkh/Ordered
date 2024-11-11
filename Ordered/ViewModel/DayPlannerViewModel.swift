//
//  DayPlannerViewModel.swift
//  Ordered
//
//  Created by Kai Hin Hung on 7/8/2024.
//

import Foundation

// This Class is adapted from Coding In A Nutshell Youtube Channel
// Source: https://www.youtube.com/watch?v=PZySRHE783s&t=845s&ab_channel=CodingInANutshell
// Modifications: I made modification to make the jumpTo looks better when it is changed from the outside
class DayPlannerViewModel: ObservableObject{
    @Published private var model = MyCalendar()
    
    var currentDate: Date{
        return model.currentDate
    }
    
    func setCurrentDate(to dateStr: String){
        model.setCurrentDate(to: dateStr)
    }
    
    func setCurrentDate(to date: Date){
        model.setCurrentDate(to: date)
    }
    
    func dates() -> [Date] {
        model.datesInYear()
    }
    
    func startDateOfWeeksInAYear() -> [Date] {
        model.startDateOfWeeksInAYear()
    }
    
    func datesInAWeek(from date: Date) -> [Date]{
        model.datesInWeek(from: date)
    }
    
    func startDateOfWeek(from date: Date) -> Date{
        model.startDateOfWeek(from: date)
    }
    
    func startDateOfCurrentDate() -> Date{
        return model.startDateOfWeek(from: currentDate)
    }
    
    func currentPositionInWeek() -> Int{
        let startOfWeek = startDateOfWeek(from: currentDate)
        let datesInAWeek = datesInAWeek(from: startOfWeek)
        let position = datesInAWeek.firstIndex(of: currentDate) ?? 0
        
        return position
    }
}
