import Foundation
import Swollama

protocol LLMServiceProtocol {
    func listModels() async throws -> [ModelListEntry]
    func getModelInfo(name: OllamaModelName) async throws -> ModelInformation
    func chat(
        messages: [ChatMessage],
        model: OllamaModelName,
        temperature: Double,
        options: ChatOptions
    ) async throws -> AsyncThrowingStream<ChatResponse, Error>
    func healthCheck() async -> Bool
    func userFriendlyError(_ error: Error) -> String
}
