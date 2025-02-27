//
//  DurationSelection.swift
//  Ordered
//
//  Created by Kai Hin Hung on 11/1/2025.
//

import SwiftUI

struct DurationSelection: View{
    @State private var selectedHour: Int = 0
    @State private var selectedMinute: Int = 0
    
    @Binding var duration: Int
    @Binding var successful: Bool
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack{
            
            HStack{
                VStack {
                    Text("Hours")
                        .font(.title3)
                        .bold()
                    
                    Picker("Hours", selection: $selectedHour) {
                        ForEach(0..<24) { hour in
                            Text("\(hour)").tag(hour)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(width: 150, height: 140)
                    .clipped()
                }
                
                // Minute Picker
                VStack {
                    Text("Minutes")
                        .font(.title3)
                        .bold()
                    
                    Picker("Minutes", selection: $selectedMinute) {
                        ForEach(0..<60) { minute in
                            Text("\(minute)").tag(minute)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(width: 150, height: 140)
                    .clipped()
                }
            }
            .padding()
            
            Button{
                withAnimation {
                    duration = selectedHour*60 + selectedMinute
                    successful = true
                    isPresented = false
                }
            } label: {
                ZStack{
                    RoundedRectangle(cornerSize: CGSize(width: 10, height: 10))
                        .fill(.color1)
                        .frame(width: 290, height: 30)
                    
                    Text("Confirm")
                        .font(.title3)
                        .foregroundStyle(.cPrimary)
                }
            }
        }
        .padding()
        .background(Color.cBackground.cornerRadius(25))
        .onAppear{
            withAnimation {
                selectedHour = duration/60
                selectedMinute = duration%60
            }
        }
    }
}
