import Foundation
import Swollama
final class ModelManager {

    static let shared = ModelManager()

    private(set) var availableModels: [ModelListEntry] = []
    private(set) var selectedModel: OllamaModelName?
    var onModelsUpdated: (([ModelListEntry]) -> Void)?
    var onModelSelected: ((OllamaModelName) -> Void)?

    private init() {}
    @MainActor
    func fetchModels() async throws {
        let models = try await OllamaService.shared.listModels()
        availableModels = models.sorted { $0.modifiedAt > $1.modifiedAt }
        if selectedModel == nil, let firstModel = models.first {
            if let modelName = OllamaModelName.parse(firstModel.name) {
                selectedModel = modelName
                onModelSelected?(modelName)
            }
        }

        onModelsUpdated?(availableModels)
    }
    @MainActor
    func selectModel(_ model: OllamaModelName) {
        selectedModel = model
        onModelSelected?(model)
        AppLogger.shared.info("Selected model: \(model.fullName)", category: .ollama)
    }
    func requireSelectedModel() throws -> OllamaModelName {
        guard let model = selectedModel else {
            throw NSError(
                domain: "ModelManager",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "No model selected"]
            )
        }
        return model
    }
}
