import UIKit

final class ViewController: UIViewController {

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.setupForAutoLayout()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16, weight: .medium)
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        testConnection()
    }

    private func setupUI() {
        view.addSubview(statusLabel)
        NSLayoutConstraint.activate([
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
        ])
    }

    private func testConnection() {
        statusLabel.text = "Testing connection to Ollama..."

        Task {
            let isHealthy = await OllamaService.shared.healthCheck()

            if isHealthy {
                do {
                    let models = try await OllamaService.shared.listModels()
                    await MainActor.run {
                        statusLabel.text = "✅ Connected!\nFound \(models.count) models"
                        AppLogger.shared.info("Connection test successful", category: .ollama)
                    }
                } catch {
                    await MainActor.run {
                        statusLabel.text =
                            "❌ Error fetching models:\n\(OllamaService.shared.userFriendlyError(error))"
                    }
                }
            } else {
                await MainActor.run {
                    statusLabel.text = "❌ Cannot connect to Ollama server"
                }
            }
        }
    }
}
