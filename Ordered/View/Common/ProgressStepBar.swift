//
//  ProgressStepBar.swift
//  Ordered
//
//  Created by Kai Hin Hung on 28/8/2024.
//

import SwiftUI

//Source code: https://www.youtube.com/watch?v=OJAW-MXkzRM&ab_channel=SuCodee 
struct ProgressStepBar: View{
    var listOfTitle: [String]
    @Binding var currentItem: Int //currentItem should be less than the number of ListOfTitle
    

    var body: some View {
        HStack(spacing: 0){
            ForEach(listOfTitle.indices, id: \.self){ i in
                
                Circle()
                    .fill(i <= currentItem ? .color3 : .color1)
                    .frame(width: 40, height: i <= currentItem ? 40 : 20)
                    .onTapGesture {
                        if i < currentItem{
                            withAnimation {
                                currentItem = i
                            }
                        }
                    }
                
                if i < listOfTitle.count - 1{
                    ZStack(alignment: .leading){
                        Rectangle()
                            .fill(i <= (currentItem - 1) ? .color3 : .color1)
                            .frame(height: 3)
                            .transition(.slide)
                        
                        Rectangle()
                            .fill(i <= (currentItem - 1) ? .color3 : .color1)
                            .frame(height: 3)
                            .frame(maxWidth: i <= (currentItem - 1) ? .infinity : 0, alignment: .leading)
                            
                    }
                }
                
            }
        }
        
    }
}

#Preview {
    ProgressStepBar(listOfTitle: K.defaultSection, currentItem: .constant(0))
}
