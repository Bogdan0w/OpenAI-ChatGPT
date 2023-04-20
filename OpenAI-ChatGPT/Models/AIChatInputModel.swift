//
//  AIChatInputModel.swift
//  OpenAI ChatGPT
//
//  Created by Nikita Bogdanov on 2023/4/12.
//  Copyright © 2023 Bogdanov Solutions ENK. All rights reserved.
//

import Foundation

enum InputViewAlert {
    case createNewChatRoom, reloadLastQuestion, clearAllQuestion, shareContents
}

class AIChatInputModel: ObservableObject {
    
    @Published var showingAlert = false
    @Published var activeAlert: InputViewAlert = .createNewChatRoom

    @Published var isShowAllChatRoom: Bool = false
    @Published var isConfigChatRoom: Bool = false
    @Published var isScrollToChatRoomTop: Bool = false
    @Published var searchText: String = ""
}
