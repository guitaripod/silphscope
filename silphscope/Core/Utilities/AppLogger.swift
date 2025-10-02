import Foundation
import OSLog

final class AppLogger {

    static let shared = AppLogger()

    private let subsystem = Bundle.main.bundleIdentifier ?? "com.guitaripod.silphscope"

    private init() {}

    enum Category: String {
        case networking = "Networking"
        case ui = "UI"
        case database = "Database"
        case ollama = "Ollama"
        case general = "General"

        var logger: Logger {
            Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.guitaripod.silphscope", category: rawValue)
        }
    }

    func log(
        _ message: String,
        category: Category = .general,
        level: OSLogType = .default,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let fileName = (file as NSString).lastPathComponent
        let logger = category.logger

        switch level {
        case .debug:
            logger.debug("[\(fileName):\(line)] \(function) - \(message)")
        case .info:
            logger.info("[\(fileName):\(line)] \(function) - \(message)")
        case .error:
            logger.error("[\(fileName):\(line)] \(function) - \(message)")
        case .fault:
            logger.fault("[\(fileName):\(line)] \(function) - \(message)")
        default:
            logger.log("[\(fileName):\(line)] \(function) - \(message)")
        }
    }

    func debug(_ message: String, category: Category = .general) {
        log(message, category: category, level: .debug)
    }

    func info(_ message: String, category: Category = .general) {
        log(message, category: category, level: .info)
    }

    func error(_ message: String, category: Category = .general) {
        log(message, category: category, level: .error)
    }

    func fault(_ message: String, category: Category = .general) {
        log(message, category: category, level: .fault)
    }
}
