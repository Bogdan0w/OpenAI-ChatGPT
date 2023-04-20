//
//  AIChatRoom.swift
//  OpenAI ChatGPT
//
//  Created by Nikita Bogdanov on 2023/4/12.
//  Copyright © 2023 Bogdanov Solutions ENK. All rights reserved.
//

import Foundation

struct ChatRoom: Codable {
    var roomID: String
    var roomName: String?
    var model: String?
    var prompt: String?
    var temperature: Double?
    var historyCount: Int = 3
}
