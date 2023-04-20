//
//  ChatInputView.swift
//  OpenAI ChatGPT
//
//  Created by Nikita Bogdanov on 2023/4/12.
//  Copyright © 2023 Bogdanov Solutions ENK. All rights reserved.
//

import SwiftUI
import SwiftUIX

struct ChatInputView: View {
    
    @Binding var searchText: String
    @StateObject var chatModel: AIChatModel
    @EnvironmentObject var model: AIChatInputModel
    @State private var isEditing = false
    
    var body: some View {
        VStack(alignment: .leading){
            inputToolBar()
            
            HStack {
                ZStack(alignment: .leading){
                    Rectangle()
                    #if os(macOS)
                        .foregroundColor(Color(NSColor.gray))
                    #else
                        .foregroundColor(Color(UIColor.tertiarySystemGroupedBackground))
                    #endif
                        .cornerRadius(20)
                        .frame(height: 40)
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(.white)
                            .padding(.leading, 8)
                            .padding(.trailing, 5)
                            .onTapGesture {
                                model.isShowAllChatRoom.toggle()
                            }
                        
                        TextView("Just ask..".localized(), text: $searchText, onEditingChanged: changedSearch(isEditing:), onCommit: fetchSearch)
                            .returnKeyType(.default)
                            .scrollIndicatorStyle(HiddenScrollViewIndicatorStyle())
                            .padding(.trailing, 3)
                            .padding([.top], 12)
                            .maxHeight(44)
                        
                        
                        if searchText.count > 0 {
                            Button(action: clearSearch) {
                                Image(systemName: "multiply.circle.fill")
                            }
                            .padding(.trailing, 5)
                            .foregroundColor(.placeholderText)
                            .buttonStyle(PlainButtonStyle())
                            
                            Button(action: fetchSearch) {
                                Image(systemName: "arrow.up.circle.fill")
                            }
                            .padding(.trailing, 8)
                            .foregroundColor(.green)
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
        }
        .padding(.bottom, 10)
    }
    
    @ViewBuilder private func inputToolBar() -> some View {
        HStack {
            Spacer()
            
        if isEditing {
                Button(action: hideKeyboard) {
                    Image(systemName: "keyboard.chevron.compact.down")
                }
                .padding(.trailing, 8)
                .foregroundColor(.lightGray)
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.bottom, 5)
    }
    
    func changedSearch(isEditing: Bool) {
        self.isEditing = isEditing
    }
    
    func fetchSearch() {
        guard !searchText.isEmpty else {
            return
        }
        #if DEBUG
        debugPrint(searchText)
        #endif
        chatModel.getChatResponse(prompt: searchText)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            clearSearch()
        }
    }
    
    func clearSearch() {
        searchText = ""
    }
}
