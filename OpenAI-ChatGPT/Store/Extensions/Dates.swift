//
//  Dates.swift
//  OpenAI ChatGPT
//
//  Created by Nikita Bogdanov on 2023/4/12.
//  Copyright © 2023 Bogdanov Solutions ENK. All rights reserved.
//

import Foundation

extension Date {
    
    public func currentDateString(_ dateFormat: String = "yyyy-MM-dd HH:mm:ss") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        let dateTimeString = formatter.string(from: self)
        return dateTimeString
    }
}
