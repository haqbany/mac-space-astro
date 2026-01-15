import SwiftUI
import AstroAI

public struct ChatMessage: Identifiable {
    public let id = UUID()
    public let text: String
    public let isUser: Bool
}

public class AstroChatViewModel: ObservableObject {
    @Published public var messages: [ChatMessage] = [
        ChatMessage(text: "Hello! I'm Astro, your technical companion. Ask me anything about your Mac's performance or internals.", isUser: false)
    ]
    @Published public var inputText: String = ""
    
    private let aiService = AstroAIService()
    
    public init() {}
    
    public func send() {
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        let userMsg = ChatMessage(text: inputText, isUser: true)
        messages.append(userMsg)
        let query = inputText
        inputText = ""
        
        Task {
            let response = await aiService.process(query: query)
            DispatchQueue.main.async {
                self.messages.append(ChatMessage(text: response.text, isUser: false))
            }
        }
    }
}

public struct AstroChatView: View {
    @StateObject var viewModel = AstroChatViewModel()
    
    public init() {}
    
    public var body: some View {
        VStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            ChatBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _ in
                    if let lastId = viewModel.messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }
            
            HStack {
                TextField("Ask Astro...", text: $viewModel.inputText)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(Color.primary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .onSubmit { viewModel.send() }
                
                Button(action: viewModel.send) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AstroTheme.accentBlue)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(VisualEffectView(material: .headerView, blendingMode: .withinWindow))
        }
    }
}

struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            
            Text(message.text)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(message.isUser ? AstroTheme.accentBlue : Color.primary.opacity(0.1))
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .frame(maxWidth: 300, alignment: message.isUser ? .trailing : .leading)
            
            if !message.isUser { Spacer() }
        }
    }
}
