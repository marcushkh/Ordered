//
//  Resting.swift
//  Ordered
//
//  Created by Kai Hin Hung on 19/5/2025.
//
import SwiftUI
import PopupView

struct LocationSelection: View{
    @ObservedObject var welcomeVM: WelcomeVM
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View{
        VStack(alignment: .leading){
            HStack{
                Spacer()
                VStack{
                    if !welcomeVM.showPopup{
                        Text("Configure the places you are active in (Max: 5)")
                            .font(.title2)
                            .bold()
                            .multilineTextAlignment(.center)
                    }
                    else{
                        Text("Select the Events that you would do in the Selected Place")
                            .font(.title2)
                            .bold()
                            .multilineTextAlignment(.center)
                    }
                    
                }
                Spacer()
            }
            
            Divider()
                .foregroundStyle(.color3)
            
            
            ScrollView{
                VStack{
                    ForEach(LocationType.allCases, id: \.self){ location in
                        ZStack{
                            RoundedRectangle(cornerRadius: 20.0)
                                .fill(.color1)
                            
                            HStack{
                                Image(location.rawValue)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 40)
                                
                                Text(location.rawValue.capitalizedFirst)
                                    
                                Spacer()
                            }
                            .frame(height: 60)
                            .padding(.horizontal)
                        }
                        .onTapGesture {
                            let newLocation = Location.createNew(in: Model.viewContext, 
                                                               imageName: location.rawValue,
                                                               colorScheme: colorScheme)
                            
                            if let newLocation = newLocation {
                                welcomeVM.location = newLocation
                                welcomeVM.showPopup = true
                            }
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        
    }
}
