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

    private var currentStreamingTask: Task<Void, Never>?
    private var streamBuffer = ""
    private var streamingMessageIndex: Int?
    private var chunkBuffer: [String] = []

    func sendMessage(_ text: String) async {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard !isGenerating else { return }
        guard let model = ModelManager.shared.selectedModel else {
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
        let assistantIndex = messages.count - 1

        currentStreamingTask = Task {
            await generateResponse(for: model, assistantIndex: assistantIndex)
        }
    }

    func cancelGeneration() {
        currentStreamingTask?.cancel()
        currentStreamingTask = nil
        isGenerating = false
        if let index = streamingMessageIndex {
            flushChunkBuffer()
            messages[index].isStreaming = false
            streamingMessageIndex = nil
        }
        streamBuffer = ""
        chunkBuffer = []
    }

    func clearMessages() {
        messages.removeAll()
        error = nil
    }

    private func generateResponse(for model: OllamaModelName, assistantIndex: Int) async {
        streamingMessageIndex = assistantIndex
        streamBuffer = ""
        chunkBuffer = []

        do {
            let chatMessages = messages.dropLast().map { message in
                ChatMessage(role: message.role, content: message.content)
            }

            let stream = try await OllamaService.shared.chat(
                messages: Array(chatMessages),
                model: model
            )

            var isFirstUpdate = true

            for try await response in stream {
                if Task.isCancelled {
                    AppLogger.shared.debug("Stream cancelled at \(streamBuffer.count) chars", category: .ollama)
                    break
                }

                if response.done {
                    AppLogger.shared.info("✅ Chat completed: \(streamBuffer.count) chars", category: .ollama)
                    if !chunkBuffer.isEmpty {
                        flushChunkBuffer()
                    }
                    break
                }

                let chunk = response.message.content
                if !chunk.isEmpty {
                    if isFirstUpdate {
                        streamBuffer = chunk
                        messages[assistantIndex].content = streamBuffer
                        isFirstUpdate = false
                    } else {
                        chunkBuffer.append(chunk)

                        let bufferedText = chunkBuffer.joined()
                        let shouldUpdate = chunkBuffer.count >= 4 ||
                                          bufferedText.contains("\n") ||
                                          bufferedText.count > 40

                        if shouldUpdate {
                            flushChunkBuffer()
                        }
                    }
                }
            }

            if let index = streamingMessageIndex, index < messages.count {
                messages[index].isStreaming = false
            }
            streamingMessageIndex = nil
            isGenerating = false

        } catch {
            AppLogger.shared.error("Chat generation failed: \(error)", category: .ollama)

            if assistantIndex < messages.count {
                messages.remove(at: assistantIndex)
            }

            streamingMessageIndex = nil
            self.error = OllamaService.shared.userFriendlyError(error)
            isGenerating = false
        }
    }

    private func flushChunkBuffer() {
        guard !chunkBuffer.isEmpty,
              let index = streamingMessageIndex,
              index < messages.count else { return }

        let newContent = chunkBuffer.joined()
        streamBuffer += newContent
        chunkBuffer.removeAll()

        messages[index].content = streamBuffer
    }
}
