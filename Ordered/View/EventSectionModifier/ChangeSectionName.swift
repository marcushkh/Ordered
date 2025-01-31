//
//  ChangeSectionName.swift
//  Ordered
//
//  Created by Kai Hin Hung on 20/1/2025.
//
import SwiftUI

struct ChangeSectionName: View{
    @FocusState var typingSectionName: Bool
    @State var name: String = ""
    @State var color: String = ""
    
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject var viewModel: ContentViewModel

    var body: some View{
        HStack{
            ColorPicker("", selection: Binding(get: {
                Color(hex: color)
            }, set: { c in
                var colorSuggested: String{
                    if colorScheme == .light{
                        K.defaultSectionColor[(viewModel.insertToCal?.section_cals?.count ?? 0) % K.defaultSectionColor.count]
                    }
                    else{
                        K.defaultSectionColorDark[(viewModel.insertToCal?.section_cals?.count ?? 0) % K.defaultSectionColorDark.count]
                    }
                }
                color = c.toHex() ?? colorSuggested
            }))
            .labelsHidden()
            .overlay{
                Circle()
                    .fill(Color(hex: color))
                    .frame(width: K.medium_size, height: K.medium_size)
            }
            
            TextField("Section Name", text: $name)
                .focused($typingSectionName)
            
            Spacer()
            
            Button {
                
                if name.isEmpty{
                    typingSectionName = true
                }
                else{
                    Section_Cal.save(name: name, color: color, sc: viewModel.changeSection_Cal, cal: viewModel.insertToCal)
                    
                    viewModel.refresh.toggle()
                    viewModel.showChangeSection = false
                }
            } label: {
                ZStack{
                    RoundedRectangle(cornerSize: CGSize(width: 10, height: 10))
                        .fill(.success)
                        .frame(width: 40, height: 25)
                    
                    Image(systemName: "arrow.up")
                        .foregroundStyle(.black)
                }
            }
            
        }
        .onAppear{
            var colorSuggested: String{
                if colorScheme == .light{
                    K.defaultSectionColor[(viewModel.insertToCal?.section_cals?.count ?? 0) % K.defaultSectionColor.count]
                }
                else{
                    K.defaultSectionColorDark[(viewModel.insertToCal?.section_cals?.count ?? 0) % K.defaultSectionColorDark.count]
                }
            }
            name = viewModel.changeSection_Cal?.name ?? ""
            color = viewModel.changeSection_Cal?.color ?? colorSuggested
            typingSectionName = true
        }
        .padding(.vertical)
        .padding(.horizontal, K.horizontal_padding)
        .background()
        .padding(.bottom, -10)
    }
}

#Preview {
    ChangeSectionName(viewModel: ContentViewModel())
}
