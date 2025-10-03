import Foundation
import Swollama

protocol ModelManagerProtocol {
    var availableModels: [ModelListEntry] { get }
    var selectedModel: OllamaModelName? { get }
    var onModelsUpdated: (([ModelListEntry]) -> Void)? { get set }
    var onModelSelected: ((OllamaModelName) -> Void)? { get set }

    func fetchModels() async throws
    func selectModel(_ model: OllamaModelName)
    func requireSelectedModel() throws -> OllamaModelName
}
