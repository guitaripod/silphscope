import Foundation
import Swollama

@MainActor
final class ChatViewModel: ObservableObject {

    struct Message: Hashable, Identifiable {
        let id = UUID()
        let role: MessageRole
        var content: String
        let timestamp: Date
        var isStreaming: Bool

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
            hasher.combine(content)
        }

        static func == (lhs: Message, rhs: Message) -> Bool {
            lhs.id == rhs.id && lhs.content == rhs.content
        }
    }

    @Published private(set) var messages: [Message] = []
    @Published private(set) var isGenerating = false
    @Published private(set) var error: String?

    private let llmService: LLMServiceProtocol
    private let modelManager: ModelManagerProtocol
    private let streamingHandler: StreamingHandler
    private var streamingMessageIndex: Int?

    init(
        llmService: LLMServiceProtocol = OllamaService.shared,
        modelManager: ModelManagerProtocol = ModelManager.shared,
        streamingHandler: StreamingHandler = StreamingHandler()
    ) {
        self.llmService = llmService
        self.modelManager = modelManager
        self.streamingHandler = streamingHandler
        self.streamingHandler.delegate = self
    }

    func sendMessage(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard !isGenerating else { return }
        guard let model = modelManager.selectedModel else {
            error = "No model selected"
            return
        }
        AppLogger.shared.info("📤 Sending: '\(text)' [\(text.count) chars]", category: .ui)

        let userMessage = Message(
            role: .user,
            content: text,
            timestamp: Date(),
            isStreaming: false
        )
        messages.append(userMessage)
        isGenerating = true
        error = nil
        let assistantMessage = Message(
            role: .assistant,
            content: "",
            timestamp: Date(),
            isStreaming: true
        )
        messages.append(assistantMessage)
        streamingMessageIndex = messages.count - 1

        await generateResponse(for: model)
    }

    func cancelGeneration() {
        streamingHandler.cancel()
        isGenerating = false
        if let index = streamingMessageIndex {
            messages[index].isStreaming = false
            streamingMessageIndex = nil
        }
    }

    func clearMessages() {
        messages.removeAll()
        error = nil
    }

    private func generateResponse(for model: OllamaModelName) async {
        do {
            let chatMessages = messages.dropLast().map { message in
                ChatMessage(role: message.role, content: message.content)
            }

            let stream = try await llmService.chat(
                messages: Array(chatMessages),
                model: model,
                temperature: 0.7,
                options: .default
            )

            streamingHandler.startStreaming(stream)

        } catch {
            AppLogger.shared.error("Chat generation failed: \(error)", category: .ollama)

            if let index = streamingMessageIndex {
                messages.remove(at: index)
            }

            streamingMessageIndex = nil
            self.error = llmService.userFriendlyError(error)
            isGenerating = false
        }
    }
}

extension ChatViewModel: StreamingHandlerDelegate {

    func streamingHandler(_ handler: StreamingHandler, didUpdateContent content: String) {
        guard let index = streamingMessageIndex, index < messages.count else { return }
        messages[index].content = content
    }

    func streamingHandler(_ handler: StreamingHandler, didCompleteWithContent content: String) {
        guard let index = streamingMessageIndex, index < messages.count else { return }
        messages[index].content = content
        messages[index].isStreaming = false
        streamingMessageIndex = nil
        isGenerating = false
    }

    func streamingHandler(_ handler: StreamingHandler, didFailWithError error: Error) {
        if let index = streamingMessageIndex {
            messages.remove(at: index)
        }

        streamingMessageIndex = nil
        self.error = llmService.userFriendlyError(error)
        isGenerating = false
    }
}
