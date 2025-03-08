//
//  WelcomeScreenMaster.swift
//  NoMoreSnacks
//
//  Created by Kai Hin Hung on 8/7/2024.
//

import SwiftUI

//Source: My previous app: No more snack
struct WelcomeScreenMaster: View {
    
    @State var page = 1
    @Binding var isWelcomeScreen: Bool
    
    init(isWelcomeScreen: Binding<Bool>) {
        self._isWelcomeScreen = isWelcomeScreen
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(Color.color3)
        UIPageControl.appearance().pageIndicatorTintColor = UIColor(Color.gray)
    }
    
    var body: some View {
        VStack{
            TabView(selection: $page){
                WelcomeScreen1().tag(1)
                WelcomeScreen2().tag(2)
                WelcomeScreen3().tag(3)
                WelcomeScreen4().tag(4)
            }
            .tabViewStyle(.page)
            
            
            
            Button(action: {
                if page < 4{
                    withAnimation {
                        page += 1
                    }
                }
                else{
                    withAnimation {
                        isWelcomeScreen = false
                    }
                }
            }, label: {
                
                ZStack {
                    Text(page < 4 ? "Next" : "Start!")
                        .font(.title2)
                        .foregroundStyle(Color(.white))
                        .bold()
                        .padding([.top, .bottom], 10)
                        .padding([.leading, .trailing], UIScreen.main.bounds.width * 0.25)
                        .background(Color.color3)
                        .clipShape(.rect(cornerRadius: 10))
                }
            })
        }
        
    }
}

#Preview {
    WelcomeScreenMaster(isWelcomeScreen: .constant(true))
}
