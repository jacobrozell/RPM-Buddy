import Foundation

enum LogLevel: Int, Comparable, Sendable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    case fault = 4

    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

enum LogCategory: String, Sendable {
    case appLifecycle
    case detector
    case settings
}

struct LogEntry: Sendable {
    let timestamp: Date
    let level: LogLevel
    let category: LogCategory
    let eventName: String
    let message: String
    let metadata: [String: String]
}
