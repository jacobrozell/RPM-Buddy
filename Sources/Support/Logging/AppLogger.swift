import Foundation

protocol AppLogger: Sendable {
    func log(
        level: LogLevel,
        category: LogCategory,
        eventName: String,
        message: String,
        metadata: [String: String]?
    )
}

extension AppLogger {
    func info(
        _ category: LogCategory,
        eventName: String,
        message: String,
        metadata: [String: String]? = nil
    ) {
        log(
            level: .info,
            category: category,
            eventName: eventName,
            message: message,
            metadata: metadata
        )
    }

    func warning(
        _ category: LogCategory,
        eventName: String,
        message: String,
        metadata: [String: String]? = nil
    ) {
        log(
            level: .warning,
            category: category,
            eventName: eventName,
            message: message,
            metadata: metadata
        )
    }

    func error(
        _ category: LogCategory,
        eventName: String,
        message: String,
        metadata: [String: String]? = nil
    ) {
        log(
            level: .error,
            category: category,
            eventName: eventName,
            message: message,
            metadata: metadata
        )
    }
}
