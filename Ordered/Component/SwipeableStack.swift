//
//  SwapeableStack.swift
//  Ordered
//
//  Created by Kai Hin Hung on 15/8/2024.
//

import SwiftUI

struct SwipeableStack<WhateverTypeOfData: Hashable, Content>: View where Content : View{
    var WhateverData: [WhateverTypeOfData] = []
    let content: (WhateverTypeOfData, ViewPosition) -> Content
    var jumpTo: WhateverTypeOfData?
    
    @State private var dragged = CGSize.zero
    @State var dataIndex = 1
    
    var previousExist: Bool{
        return (dataIndex - 1) >= 0
    }
    var nextExist: Bool{
        return dataIndex < (WhateverData.count - 1)
    }
    
    init(_ data: [WhateverTypeOfData], jumpTo: WhateverTypeOfData? = nil, @ViewBuilder content: @escaping (WhateverTypeOfData, ViewPosition) -> Content) {
        self.WhateverData = data
        self.content = content
        if let jumpTo{
            self.jumpTo = jumpTo
        }
        
    }
    
    var body: some View{
        GeometryReader{ geo in
            let w = geo.size.width
            let h = geo.size.height
            HStack(spacing: K.horizontal_padding * 2){
                if previousExist{
                    content(WhateverData[dataIndex - 1], .previousView) //Last week
                        .frame(width: w, height: h)
                        .offset(x: previousExist ? -w-K.horizontal_padding*2 : 0)
                }
                content(WhateverData[dataIndex], .centerView) //This week
                    .frame(width: w, height: h)
                    .offset(x: previousExist ? -w-K.horizontal_padding*2 : 0)
                if nextExist{
                    content(WhateverData[dataIndex + 1], .nextView) //Next week
                        .frame(width: w, height: h)
                        .offset(x: previousExist ? -w-K.horizontal_padding*2 : 0)
                }
            }
            .onAppear {
                if let jumpTo{
                    if let pos = WhateverData.firstIndex(of: jumpTo) {
                        dataIndex = pos
                    }
                }
            }
            .onChange(of: jumpTo, { oldValue, newValue in
                if let jumpTo{
                    if let pos = WhateverData.firstIndex(of: jumpTo) {
                        withAnimation(.bouncy) {
                            dataIndex = pos
                        }
                        
                    }
                }
            })
            .offset(x: dragged.width)
            .gesture(
                DragGesture()
                    .onChanged({ value in
                        dragged.width = value.translation.width
                    })
                    .onEnded({ value in
                        var indexOffset = 0
                        withAnimation(.smooth(duration: 0.5)) {
                            dragged = CGSize.zero
                            if value.predictedEndTranslation.width < -w/2 && nextExist{
                                dragged.width = -w - K.horizontal_padding*2
                                indexOffset = 1 //Next
                            }
                            if value.predictedEndTranslation.width > w/2 && previousExist{
                                dragged.width = w + K.horizontal_padding*2
                                indexOffset = -1 //Previous
                            }
                            
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5){
                            dragged = CGSize.zero
                            if indexOffset == 1 && nextExist{
                                dataIndex += indexOffset
                            }
                            if indexOffset == -1 && previousExist{
                                dataIndex += indexOffset
                            }
                        }
                    })
            )
        }
    }
}
