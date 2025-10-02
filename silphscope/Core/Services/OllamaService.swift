import Foundation
import Swollama

final class OllamaService {

    static let shared = OllamaService()

    private let client: OllamaClient
    private let baseURL: URL

    private init() {
       
        self.baseURL = URL(string: "http://192.168.1.197:11434")!
        let configuration = OllamaConfiguration(
            timeoutInterval: 120,
            maxRetries: 3,
            retryDelay: 2.0,
            defaultKeepAlive: 300
        )

        self.client = OllamaClient(
            baseURL: baseURL,
            configuration: configuration
        )

        AppLogger.shared.info("OllamaService initialized with baseURL: \(baseURL.absoluteString)", category: .ollama)
    }
    func listModels() async throws -> [ModelListEntry] {
        return try await client.listModels()
    }
    func getModelInfo(name: OllamaModelName) async throws -> ModelInformation {
        AppLogger.shared.debug("Fetching info for model: \(name.fullName)", category: .ollama)

        do {
            let info = try await client.showModel(name: name, verbose: false)
            AppLogger.shared.info("Successfully fetched info for \(name.fullName)", category: .ollama)
            return info
        } catch {
            AppLogger.shared.error("Failed to fetch model info: \(error.localizedDescription)", category: .ollama)
            throw error
        }
    }
    func chat(
        messages: [ChatMessage],
        model: OllamaModelName,
        temperature: Double = 0.7,
        options: ChatOptions = .default
    ) async throws -> AsyncThrowingStream<ChatResponse, Error> {
        AppLogger.shared.debug("Starting chat with model: \(model.fullName)", category: .ollama)

        do {
            var chatOptions = options
            if options.modelOptions == nil {
                chatOptions = ChatOptions(
                    modelOptions: ModelOptions(
                        numPredict: -1,
                        temperature: temperature,
                        numCtx: 8192
                    )
                )
            }

            let stream = try await client.chat(
                messages: messages,
                model: model,
                options: chatOptions
            )

            AppLogger.shared.info("Chat stream started - numPredict: \(chatOptions.modelOptions?.numPredict ?? 0), numCtx: \(chatOptions.modelOptions?.numCtx ?? 0)", category: .ollama)
            return stream
        } catch {
            AppLogger.shared.error("Failed to start chat: \(error.localizedDescription)", category: .ollama)
            throw error
        }
    }
    func healthCheck() async -> Bool {
        AppLogger.shared.debug("Performing health check", category: .ollama)

        do {
            let version = try await client.getVersion()
            AppLogger.shared.info("Server healthy - version: \(version.version)", category: .ollama)
            return true
        } catch {
            AppLogger.shared.error("Health check failed: \(error.localizedDescription)", category: .ollama)
            return false
        }
    }
    func userFriendlyError(_ error: Error) -> String {
        if let ollamaError = error as? OllamaError {
            switch ollamaError {
            case .modelNotFound:
                return "Model not found. Please check if it's downloaded."
            case .serverError(let message):
                return "Server error: \(message)"
            case .networkError:
                return "Network error. Check your connection to \(baseURL.host ?? "server")."
            case .invalidResponse:
                return "Invalid response from server."
            case .decodingError:
                return "Failed to decode server response."
            case .invalidParameters(let message):
                return "Invalid parameters: \(message)"
            case .unexpectedStatusCode(let code):
                return "Unexpected status code: \(code)"
            case .httpError(let statusCode, let message):
                if let message = message {
                    return "HTTP error \(statusCode): \(message)"
                }
                return "HTTP error \(statusCode)"
            case .cancelled:
                return "Request was cancelled."
            case .fileError(let message):
                return "File error: \(message)"
            }
        }
        return error.localizedDescription
    }
}
