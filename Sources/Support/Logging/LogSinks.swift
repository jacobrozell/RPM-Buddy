import Foundation

protocol LogSink: Sendable {
    func write(_ entry: LogEntry)
}

struct CompositeLogSink: LogSink {
    private let sinks: [any LogSink]

    init(sinks: [any LogSink]) {
        self.sinks = sinks
    }

    func write(_ entry: LogEntry) {
        for sink in sinks {
            sink.write(entry)
        }
    }
}

struct FilteredLogSink: LogSink {
    private let minimumLevel: LogLevel
    private let wrapped: any LogSink

    init(minimumLevel: LogLevel, wrapped: any LogSink) {
        self.minimumLevel = minimumLevel
        self.wrapped = wrapped
    }

    func write(_ entry: LogEntry) {
        guard entry.level >= minimumLevel else { return }
        wrapped.write(entry)
    }
}

struct NoOpLogSink: LogSink {
    func write(_ entry: LogEntry) {}
}

protocol RemoteAnalyticsLogSink: LogSink {}

struct NoOpRemoteAnalyticsLogSink: RemoteAnalyticsLogSink {
    func write(_ entry: LogEntry) {}
}
