//
//  TokenSettingView.swift
//  OpenAI ChatGPT
//
//  Created by Nikita Bogdanov on 2023/4/12.
//  Copyright © 2023 Bogdanov Solutions ENK. All rights reserved.
//

import SwiftUI
import OpenAI

struct ChatAPISettingView: View {
    
    @Binding var isKeyPresented: Bool
    @StateObject var chatModel: AIChatModel
    
    @State private var selectedModel: Int = 0
    @State private var apiHost = kDeafultAPIHost
    @State private var apiKey = "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"
    @State private var maskedAPIKey = "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"
    @State private var apiTimeout = "\(kDeafultAPITimeout)"
    
    @State private var apiHostError = ""
    @State private var apiKeyError = ""
    @State private var apiTimeoutError = ""
    @State private var isDirty: Bool = false
    
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    private let appSubVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
    
    init(isKeyPresented: Binding<Bool>, chatModel: AIChatModel) {
        _isKeyPresented = isKeyPresented
        _chatModel = StateObject(wrappedValue: chatModel)
        
        if let savedModelName = UserDefaults.standard.string(forKey: ChatGPTModelName),
           let index = kAPIModels.firstIndex(of: savedModelName) {
            _selectedModel = State(initialValue: index)
        } else {
            _selectedModel = State(initialValue: 0)
        }
        
        if let lastHost = UserDefaults.standard.string(forKey: ChatGPTAPIHost) {
            _apiHost = State(initialValue: lastHost)
        }
        
        if let lastTime = UserDefaults.standard.string(forKey: ChatGPTAPITimeout) {
            _apiTimeout = State(initialValue: lastTime)
        }
        
        if let lastKey = lastOpenAIKey() {
            _maskedAPIKey = State(initialValue: lastKey)
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("API Model".localized())) {
                    Picker(selection: $selectedModel, label: Text("Deafult API Model".localized())) {
                        ForEach(0..<kAPIModels.count, id: \.self) {
                            Text(kAPIModels[$0])
                        }
                    }
                }
                
                Section(header: Text("API Host".localized())) {
                    TextField("For example: ".localized() + kDeafultAPIHost, text: $apiHost)
                    if !apiHostError.isEmpty {
                        HStack {
                            Text(apiHostError)
                                .foregroundColor(.red)
                                
                            Spacer()
                            
                            Button(action: {
                                apiHost = kDeafultAPIHost
                            }) {
                                Text("Use Default".localized())
                                    .foregroundColor(.blue)
                                    .font(.footnote)
                            }
                        }
                    }
                }
                
                Section(header: Text("API Key".localized())) {
                    TextField("Please enter OpenAI Key".localized(), text: $apiKey)
                    if !apiKeyError.isEmpty {
                        Text(apiKeyError)
                            .foregroundColor(.red)
                    }
                    if !maskedAPIKey.isEmpty {
                        HStack {
                            Text("Current use Key: ".localized() + maskedAPIKey)
                                .foregroundColor(.gray)
                                .font(.footnote)
                                
                            Spacer()
                            
                            Button(action: {
                                UserDefaults.standard.set(nil, forKey: ChatGPTOpenAIKey)
                                maskedAPIKey = ""
                            }) {
                                Text("Delete".localized())
                                    .foregroundColor(.red)
                                    .font(.footnote)
                            }
                        }
                    }
                }
                
                Section(header: Text("API Timeout".localized())) {
                    TextField("API Request timeout (seconds)".localized(), text: $apiTimeout)
                        .keyboardType(.numberPad)
                    if !apiTimeoutError.isEmpty {
                        Text(apiTimeoutError)
                            .foregroundColor(.red)
                    }
                }
                
                aboutAppSection
            }
            .listStyle(GroupedListStyle())
            .navigationTitle("Settings".localized())
            .navigationBarItems(
                trailing:
                    HStack {
                        Button(action: saveSettings, label: {
                            Text("Save".localized()).bold()
                        }).disabled(!isDirty)

                        Button(action: onCloseButtonTapped) {
                            Image(systemName: "xmark.circle").imageScale(.large)
                        }
                    }
            )
            .onChange(of: selectedModel) { _ in
                self.isDirty = validateSettings()
            }
            .onChange(of: [apiHost, apiKey, apiTimeout]) { _ in
                self.isDirty = validateSettings()
            }
            .gesture(
                TapGesture(count: 2).onEnded {
                    hideKeyboard()
                }
            )
        }
    }

    private func saveSettings() {
        
        if !validateSettings() {
            return
        }
        
        // Save settings to UserDefaults
        UserDefaults.standard.set(kAPIModels[selectedModel], forKey: ChatGPTModelName)
        UserDefaults.standard.set(apiHost, forKey: ChatGPTAPIHost)
        if !apiKey.isEmpty {
            UserDefaults.standard.set(apiKey, forKey: ChatGPTOpenAIKey)
        }
        UserDefaults.standard.set(apiTimeout, forKey: ChatGPTAPITimeout)
        isKeyPresented = false
        chatModel.isRefreshSession = true
    }
    
    @discardableResult
    private func validateSettings() -> Bool {
        apiHostError = ""
        apiKeyError = ""
        apiTimeoutError = ""
        
        guard !apiHost.isEmpty, (URL(string: "https://" + apiHost) != nil) else {
            apiHostError = "API host format is incorrect!".localized()
            return false
        }
        
        let apiKeyString = UserDefaults.standard.string(forKey: ChatGPTOpenAIKey) ?? ""
        guard !apiKey.isEmpty || !apiKeyString.isEmpty else {
            apiKeyError = "OpenAI Key cannot be empty".localized()
            return false
        }
        guard !apiTimeout.isEmpty, let timeoutValue = Int(apiTimeout), timeoutValue > 0 else {
            apiTimeoutError = "API timeout must be a number".localized()
            return false
        }
        
        return true
    }
    
    private func onCloseButtonTapped() {
        isKeyPresented = false
    }
    
    private func lastOpenAIKey() -> String? {
        guard let inputString = UserDefaults.standard.string(forKey: ChatGPTOpenAIKey) else { return nil }
        guard inputString.count > 6 else { return inputString }
        let firstThree = inputString.prefix(3)
        let lastThree = inputString.suffix(3)
        let masked = String(repeating: "*", count: min(inputString.count - 6, 10))
        return "\(firstThree)\(masked)\(lastThree)"
    }
    
    private var aboutAppSection: some View {
        Section(header: Text("About App".localized())) {
            ScrollView {
                VStack {
                    Text("v \(appVersion ?? "") (\(appSubVersion ?? ""))")
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.bottom, 10)

                    Text(.init("Developer: 37 Mobile iOS Tech Team\nGitHub: https://github.com/37iOS/iChatGPT".localized()))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 10)

                    Text("Contributors：[@iHTCboy](https://github.com/iHTCboy) | [@AlphaGogoo](https://github.com/AlphaGogoo) | [@RbBtSn0w](https://github.com/RbBtSn0w) | [@0xfeedface1993](https://github.com/0xfeedface1993)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxHeight: 120)
        }
    }
}
