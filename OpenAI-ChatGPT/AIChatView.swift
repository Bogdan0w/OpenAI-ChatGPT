//
//  AIChatView.swift
//  OpenAI ChatGPT
//
//  Created by Nikita Bogdanov on 2023/4/12.
//  Copyright © 2023 Bogdanov Solutions ENK. All rights reserved.
//

import SwiftUI
import MarkdownText

extension View {
    func hideListRowSeperator() -> some View {
        if #available(iOS 15, *) {
            return AnyView(self.listRowSeparator(.hidden))
        } else {
            return AnyView(self.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .listRowInsets(EdgeInsets(top: -1, leading: -1, bottom: -1, trailing: -1))
                .background(Color(.systemBackground)))
        }
    }
}

struct AIChatView: View {
    @State private var animateGradient = true
    @State private var messageAnimate = false
    @State private var isRotating = 0.0
    @State private var isScrollListTop: Bool = false
    @State private var isSettingsPresented: Bool = false
    @State private var isSharing = false
    @StateObject private var chatModel = AIChatModel(roomID: ChatRoomStore.shared.lastRoomId())
    @StateObject private var inputModel = AIChatInputModel()
    @StateObject private var shareContent = ShareContent()
    
    var body: some View {
        NavigationView {
            VStack {
                chatList
                Spacer()
                ChatInputView(searchText: $inputModel.searchText, chatModel: chatModel)
                    .padding([.leading, .trailing], 12)
            }
            .markdownHeadingStyle(.custom)
            .markdownQuoteStyle(.custom)
            .markdownCodeStyle(.custom)
            .markdownInlineCodeStyle(.custom)
            .markdownOrderedListBulletStyle(.custom)
            .markdownUnorderedListBulletStyle(.custom)
            .markdownImageStyle(.custom)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: addButton)
            .sheet(isPresented: $isSettingsPresented) {
                ChatAPISettingView(isKeyPresented: $isSettingsPresented, chatModel: chatModel)
            }
            .sheet(isPresented: $inputModel.isShowAllChatRoom) {
                ChatHistoryListView(isKeyPresented: $inputModel.isShowAllChatRoom, chatModel: chatModel, onComplete: { roomID in
                    if roomID != chatModel.roomID {
                        chatModel.resetRoom(roomID)
                        isScrollListTop.toggle()
                    }
                })
            }
            .sheet(isPresented: $inputModel.isConfigChatRoom) {
                ChatRoomConfigView(isKeyPresented: $inputModel.isConfigChatRoom, chatModel: chatModel)
            }
            .sheet(isPresented: $isSharing) {
                ActivityView(activityItems: $shareContent.activityItems)
            }
            .alert(isPresented: $inputModel.showingAlert) {
                switch inputModel.activeAlert {
                case .createNewChatRoom:
                    return CreateNewChatRoom()
                case .reloadLastQuestion:
                    return ReloadLastQuestion()
                case .clearAllQuestion:
                    return ClearAllQuestion()
                case .shareContents:
                    return ShareContents()
                }
            }
            .onChange(of: inputModel.isScrollToChatRoomTop) { _ in
                isScrollListTop.toggle()
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Image("chatgpt").resizable()
                            .frame(width: 25, height: 25)
                        Text("Bogdanov ChatGPT Client").font(Font.custom("Pacifico", size: 18))
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .environmentObject(inputModel)
    }
    
    @ViewBuilder
    var chatList: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(chatModel.contents, id: \.datetime) { item in
                        VStack(alignment: .leading) {
                            HStack(alignment: .top) {
                                IconAvatarImageView(name: "chatgpt-icon-user", stroke: true)
                                MarkdownText(item.issue.replacingOccurrences(of: "\n", with: "\n\n"))
                                    .padding(.top, 2)
                            }
                            Divider()
                            HStack(alignment: .top) {
                                IconAvatarImageView(name: item.model.hasPrefix("gpt-4") ? "chatgpt-icon-4" : "chatgpt-icon")
                                if item.isResponse {
                                    MarkdownText(item.answer ?? "")
                                        .padding(.top, 2)
                                } else {
                                    Image("chatgpt").resizable()
                                        .frame(width: 25, height: 25)
                                        .rotationEffect(.degrees(isRotating))
                                        .onAppear {
                                                        withAnimation(.linear(duration: 1)
                                                            .speed(0.5).repeatForever(autoreverses: false)) {
                                                            isRotating = 360.0
                                                        }
                                                    }
                                }
                            }
                            .padding([.top, .bottom], 3)
                        }.contextMenu {
                            ChatContextMenu(searchText: $inputModel.searchText, chatModel: chatModel, item: item)
                        
                        }
                    .padding()
                    .background(LinearGradient(colors: [.init(hexadecimal: "7d89c1"), .init(hexadecimal: "485fe8"), .init(hexadecimal: "3bf048")], startPoint: .topLeading, endPoint: .bottomTrailing)
                        .hueRotation(.degrees(animateGradient ? 45 : 0))
                        .ignoresSafeArea()
                        .overlay {
                                ZStack {
                                    Color(white: 0.2, opacity: 0.15)
                                }
                            }
                        .onAppear {
                            withAnimation(.easeInOut(duration: 5.0).repeatForever(autoreverses: true)) {
                                animateGradient.toggle()
                            }
                        })
                    .cornerRadius(25)
                    .padding(.horizontal, 6.0)
                    .padding(.top, 15.0)
                    .transition(.opacity)
                    .animation(.linear, value: messageAnimate)
                    .hideListRowSeperator()
                }
            }
            .listStyle(.plain)
            .onChange(of: chatModel.isScrollListBottom) { _ in
                if let lastId = chatModel.contents.last?.datetime {
                    // try fix macOS crash
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        withAnimation {
                            proxy.scrollTo(lastId, anchor: .trailing)
                        }
                    }
                }
            }
            .onChange(of: isScrollListTop) { _ in
                if let firstId = chatModel.contents.first?.datetime {
                    withAnimation {
                        proxy.scrollTo(firstId, anchor: .leading)
                    }
                }
            }
        }
    }
    
    private var addButton: some View {
        Button(action: {
            inputModel.isConfigChatRoom.toggle()
        }) {
            HStack {
                    Image(systemName: "gearshape").imageScale(.large)
                    .foregroundColor(.black)
                }
            }
            .frame(height: 40)
            .padding(.trailing, 5)
        }
    }

// MARK: - Handle Input Toolbar Event
extension AIChatView {
    
    func CreateNewChatRoom() -> Alert {
        Alert(
            title: Text("Open a new conversation".localized()),
            message: Text("The current chat log will be saved and closed, and a new chat session will be created.".localized()),
            primaryButton: .default(Text("Create".localized())) {
                chatModel.resetRoom(nil)
            },
            secondaryButton: .cancel()
        )
    }
    
    func ReloadLastQuestion() -> Alert {
        Alert(
            title: Text("Re-ask".localized()),
            message: Text("Re-request the last question.".localized()),
            primaryButton: .default(Text("OK".localized())) {
                if let issue = chatModel.contents.last?.issue {
                    chatModel.getChatResponse(prompt: issue)
                }
            },
            secondaryButton: .cancel()
        )
    }
    
    func ClearAllQuestion() -> Alert {
        Alert(
            title: Text("Clear current conversation".localized()),
            message: Text("Clears the current conversation and deletes the saved conversation history.".localized()),
            primaryButton: .destructive(Text("Clear".localized())) {
                chatModel.contents.removeAll()
            },
            secondaryButton: .cancel()
        )
    }
    
    func ShareContents() -> Alert {
        Alert(title: Text("Share".localized()),
              message: Text("Choose a sharing format".localized()),
              primaryButton: .default(Text("Image".localized())) {
                screenshotAndShare(isImage: true)
              },
              secondaryButton: .default(Text("PDF".localized())) {
                screenshotAndShare(isImage: false)
              }
        )
    }
}



// MARK: - Handle Share Image/PDF
extension AIChatView {
    
    private func screenshotAndShare(isImage: Bool) {
        if let image = screenshot() {
            if isImage {
                shareContent.activityItems = [image]
                isSharing = true
            } else {
                if let pdfData = imageToPDFData(image: image) {
                    let temporaryDirectoryURL = FileManager.default.temporaryDirectory
                    let fileName = "iChatGPT-Screenshot.pdf"
                    let fileURL = temporaryDirectoryURL.appendingPathComponent(fileName)
                    
                    do {
                        try pdfData.write(to: fileURL, options: .atomic)
                        shareContent.activityItems = [fileURL]
                        isSharing = true
                    } catch {
                        print("Error writing PDF data to file: \(error)")
                    }
                }
            }
        }
    }
    
    private func screenshot() -> UIImage? {
        let controller = UIHostingController(rootView: self)
        let view = controller.view

        let targetSize = UIScreen.main.bounds.size
        view?.frame = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear

        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
    
    private func imageToPDFData(image: UIImage) -> Data? {
        let pdfRenderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: image.size))
        let pdfData = pdfRenderer.pdfData { (context) in
            context.beginPage()
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
        return pdfData
    }
}

class ShareContent: ObservableObject {
    @Published var activityItems: [Any] = []
}

// MARK: Render UIActivityViewController
struct ActivityView: UIViewControllerRepresentable {
    @Binding var activityItems: [Any]

    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityView>) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityView>) {
    }
}

// MARK: Avatar Image View
struct AvatarImageView: View {
    let url: String
    
    var body: some View {
        Group {
            ImageLoaderView(urlString: url) {
                Color(.tertiarySystemGroupedBackground)
            } image: { image in
                image.resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 25, height: 25)
            }
        }
        .cornerRadius(5)
        .frame(width: 25, height: 25)
        .padding(.trailing, 10)
    }
}

struct IconAvatarImageView: View {
    let name: String
    var stroke: Bool = false

    var body: some View {
        HStack {
            if stroke {
                Image(name)
                    .resizable()
                    .frame(width: 25, height: 25)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.lightGray, lineWidth: 0.1)
                    )
            } else {
                Image(name)
                    .resizable()
                    .frame(width: 25, height: 25)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
        }
        .padding(.trailing, 10)
    }
}

struct AIChatView_Previews: PreviewProvider {
    static var previews: some View {
        AIChatView()
    }
}
