import Foundation
import Swollama

@MainActor
final class ModelListViewModel: ObservableObject {

    enum State {
        case idle
        case loading
        case loaded([ModelListEntry])
        case error(String)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var selectedModel: OllamaModelName?

    func loadModels() async {
        state = .loading

        do {
            let models = try await OllamaService.shared.listModels()
            AppLogger.shared.info("Fetched \(models.count) models from Ollama", category: .ollama)
            state = .loaded(models)

            if selectedModel == nil, let firstModel = models.first,
                let modelName = OllamaModelName.parse(firstModel.name)
            {
                selectedModel = modelName
                ModelManager.shared.selectModel(modelName)
            }
        } catch {
            let errorMessage = OllamaService.shared.userFriendlyError(error)
            state = .error(errorMessage)
            AppLogger.shared.error("Failed to load models: \(error)", category: .ollama)
        }
    }

    func selectModel(_ model: ModelListEntry) {
        guard let modelName = OllamaModelName.parse(model.name) else {
            AppLogger.shared.error("Invalid model name: \(model.name)", category: .ollama)
            return
        }

        selectedModel = modelName
        ModelManager.shared.selectModel(modelName)
        AppLogger.shared.info("Selected model: \(modelName.fullName)", category: .ollama)
    }
}
