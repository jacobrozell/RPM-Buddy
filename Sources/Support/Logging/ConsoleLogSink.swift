import Foundation
import OSLog

struct ConsoleLogSink: LogSink {
    private let subsystem: String

    init(subsystem: String = "com.jacobrozell.rpmbuddy") {
        self.subsystem = subsystem
    }

    func write(_ entry: LogEntry) {
        let logger = Logger(subsystem: subsystem, category: entry.category.rawValue)
        logger.log(level: entry.level.osLogType, "\(formattedMessage(for: entry), privacy: .public)")
    }

    private func formattedMessage(for entry: LogEntry) -> String {
        let metadataPart = entry.metadata.isEmpty ? "" : " metadata=\(entry.metadata)"
        return "[\(entry.eventName)] \(entry.message)\(metadataPart)"
    }
}

private extension LogLevel {
    var osLogType: OSLogType {
        switch self {
        case .debug:
            return .debug
        case .info:
            return .info
        case .warning:
            return .default
        case .error:
            return .error
        case .fault:
            return .fault
        }
    }
}
