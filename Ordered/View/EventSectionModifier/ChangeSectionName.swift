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
                    
                    // Delete / Cancel button
                    Button{
                        if viewModel.changeSection_Cal != nil{ // Delete
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
                            
                            if viewModel.changeSection_Cal != nil{
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
                            typingSectionName = true
                        }
                        else{
                            withAnimation{
                                Section_Cal.save(name: name, color: color, sc: viewModel.changeSection_Cal, cal: viewModel.insertToCal, insertIndex: viewModel.insertIndex)

                                dismiss()
                            }
                        }
                    } label: {
                        ZStack{
                            RoundedRectangle(cornerSize: CGSize(width: 10, height: 10))
                                .fill(.success)
                                .frame(width: 40, height: 25)
                            
                            Image(systemName: "arrow.up")
                                .foregroundStyle(.cPrimary)
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
                .alert(isPresented: $showAlert) {
                    Alert(  title: Text("Delete SectionX"),
                            message: Text("Are you sure you want to delete this Section?"),
                            primaryButton: .destructive(Text("Delete")) {
                                viewModel.changeSection_Cal?.delete()
                                dismiss()
                            },
                            secondaryButton: .cancel())
                }
                .padding(.vertical)
                .padding(.horizontal, K.horizontal_padding)
                .background()
            }
        }
    }
    
    func dismiss(){
        typingSectionName = false
        viewModel.showChangeSection = false
        viewModel.changeSection_Cal = nil
        viewModel.insertToCal = nil
        viewModel.insertIndex = nil
        viewModel.refresh.toggle()
    }
}

#Preview {
    ChangeSectionName(viewModel: ContentViewModel())
}
