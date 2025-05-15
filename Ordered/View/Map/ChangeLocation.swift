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
    @State var selectedColor: Color = .color3
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
                    ColorPicker("", selection: $selectedColor, supportsOpacity: false)
                    .labelsHidden()
                    .overlay{
                        Circle()
                            .fill(selectedColor)
                            .frame(width: K.medium_size, height: K.medium_size)
                    }
                    .onChange(of: selectedColor) { oldValue, newValue in
                        if let hexString = newValue.toHex() {
                            color = hexString
                            print("Color changed to: \(color)")
                        }
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
                    name = viewModel.changeLocation?.name ?? ""
                    color = viewModel.changeLocation?.color ?? "F3B757"
                    selectedColor = Color(hex: color)
                    typingLocationName = true
                }
                .padding(.vertical)
                .padding(.horizontal, K.horizontal_padding)
                .background()
            }
        }
        .alert("Delete Location?", isPresented: $showAlert) {
            Button("Cancel", role: .cancel) { }
            
            Button("Delete", role: .destructive) {
                if let location = viewModel.changeLocation {
                    if location.delete(from: Model.viewContext) {
                        dismiss()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this location? This action cannot be undone.")
        }
    }
    
    func dismiss(){
        typingLocationName = false
        viewModel.showChangeLocation = false
        viewModel.changeLocation = nil
        viewModel.refresh.toggle()
    }
}
