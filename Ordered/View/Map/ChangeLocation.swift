//
//  ChangeSectionName.swift
//  Ordered
//
//  Created by Kai Hin Hung on 20/1/2025.
//
import SwiftUI

struct ChangeLocation: View{
    @FocusState var typingLocationName: Bool
    @State var name: String = ""
    @State var color: String = ""
    @State var showAlert: Bool = false
    
    @Environment(\.colorScheme) var colorScheme
    
    @ObservedObject var viewModel: ContentViewModel

    var body: some View{
        
        ZStack{
            //Background
            Color(.cPrimary.opacity(0.2))
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        dismiss()
                    }
                }
            
            VStack{
                Spacer()
                HStack{
                    ColorPicker("", selection: Binding(get: {
                        Color(hex: color)
                    }, set: { c in
                        color = c.toHex() ?? "F3B757"
                    }), supportsOpacity: false)
                    .labelsHidden()
                    .overlay{
                        Circle()
                            .fill(Color(hex: color))
                            .frame(width: K.medium_size, height: K.medium_size)
                    }
                    .onChange(of: color) { oldValue, newValue in
                        print(color)
                    }
                    
                    TextField("Location Name", text: $name)
                        .focused($typingLocationName)
                    
                    Spacer()
                    
                    // Delete / Cancel button
                    Button{
                        if viewModel.changeLocation != nil{ // Delete
                            showAlert = true
                        }
                        else{
                            dismiss()
                        }
                    } label: {
                        ZStack{
                            RoundedRectangle(cornerSize: CGSize(width: 10, height: 10))
                                .fill(.error)
                                .frame(width: 40, height: 25)
                            
                            if viewModel.changeLocation != nil {
                                Image(systemName: "trash")
                                    .foregroundStyle(.cPrimary)
                            }
                            else{
                                Image(systemName: "xmark")
                                    .foregroundStyle(.cPrimary)
                            }
                        }
                    }
                    
                    // Save/Success Button
                    Button {
                        if name.isEmpty{
                            typingLocationName = true
                        }
                        else{
                            withAnimation{
                                Location.save(name: name, color: color, location: viewModel.changeLocation)
                                dismiss()
                            }
                        }
                    } label: {
                        ZStack{
                            RoundedRectangle(cornerSize: CGSize(width: 10, height: 10))
                                .fill(.success)
                                .frame(width: 40, height: 25)
                            
                            Image(systemName: "square.and.arrow.down")
                                .foregroundStyle(.cPrimary)
                        }
                    }
                    
                }
                .onAppear{
                    print(viewModel.changeLocation)
                    name = viewModel.changeLocation?.name ?? ""
                    color = viewModel.changeLocation?.color ?? "F3B757"
                    typingLocationName = true
                }
                .padding(.vertical)
                .padding(.horizontal, K.horizontal_padding)
                .background()
            }
        }
    }
    
    func dismiss(){
        typingLocationName = false
        viewModel.showChangeLocation = false
        viewModel.changeLocation = nil
        viewModel.refresh.toggle()
    }
}
