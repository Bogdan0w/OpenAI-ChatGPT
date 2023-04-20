//
//  ChatContextMenu.swift
//  OpenAI ChatGPT
//
//  Created by Nikita Bogdanov on 2023/4/12.
//  Copyright © 2023 Bogdanov Solutions ENK. All rights reserved.
//

import SwiftUI

struct ChatContextMenu: View {
    
    @Binding var searchText: String
    @StateObject var chatModel: AIChatModel
    @EnvironmentObject var model: AIChatInputModel
    let item: AIChat
    
    var body: some View {
        VStack {
            CreateMenuItem(text: "Copy Question".localized(), imgName: "doc.on.doc") {
                item.issue.copyToClipboard()
            }

            CreateMenuItem(text: "Copy Answer".localized(), imgName: "doc.on.doc") {
                item.answer!.copyToClipboard()
            }
            .disabled(item.answer == nil)

            CreateMenuItem(text: "Copy Question and Answer".localized(), imgName: "doc.on.doc.fill") {
                "\(item.issue)\n-----------\n\(item.answer ?? "")".copyToClipboard()
            }
            .disabled(item.answer == nil)

            CreateMenuItem(text: "New chat".localized(), imgName: "ellipsis.bubble") {
                model.activeAlert = .createNewChatRoom
                model.showingAlert.toggle()
            }

            CreateMenuItem(text: "Share data".localized(), imgName: "square.and.arrow.up.on.square") {
                model.activeAlert = .shareContents
                model.showingAlert.toggle()
            }
            CreateMenuItem(text: "Regenerate".localized(), imgName: "arrow.clockwise.circle") {
                model.activeAlert = .reloadLastQuestion
                model.showingAlert.toggle()
            }
            CreateMenuItem(text: "Clear chat".localized(), imgName: "trash") {
                model.activeAlert = .reloadLastQuestion
                model.showingAlert.toggle()
            }
            // remove item
            let isWait = chatModel.contents.filter({ $0.isResponse == false })
            
            CreateMenuItem(text: "Delete Question".localized(), imgName: "trash", isDestructive: true) {
                if let index = chatModel.contents.firstIndex(where: { $0.datetime == item.datetime })
                {
                    chatModel.contents.remove(at: index)
                }
            }
        }
    }

    func CreateMenuItem(text: String, imgName: String, isDestructive: Bool = false, onAction: (() -> Void)?) -> some View {
        if #available(iOS 15.0, *) {
            return Button(role: isDestructive ? .destructive : nil) {
                onAction?()
            } label: {
                Label(text, systemImage: imgName)
            }
        } else {
            return Button {
                onAction?()
            } label: {
                Label(text, systemImage: imgName)
            }
        }
    }
}
