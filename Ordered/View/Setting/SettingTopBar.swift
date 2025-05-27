//
//  SettingTopBar.swift
//  Ordered
//
//  Created by Kai Hin Hung on 26/5/2025.
//
import SwiftUI

struct SettingTopBar: View{
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View{
        ZStack{
            RoundedRectangle(cornerRadius: 20)
                .foregroundStyle(.color2)
                
            VStack{
                if viewModel.isSubscriptionActive{
                    Image("working")
                        .resizable()
                        .scaledToFit()
                }
                else{
                    Image("inf")
                        .resizable()
                        .scaledToFit()
                    
                    Text("Unlock Full Potential")
                        .bold()
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .padding(.bottom)
                }
            }
        }
        .frame(height: 200)
        .padding(.horizontal)
        .onTapGesture {
            viewModel.isShowPaywall = true
        }
    }
}
