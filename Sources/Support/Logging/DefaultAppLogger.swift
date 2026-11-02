import Foundation

struct DefaultAppLogger: AppLogger {
    private let minimumLevel: LogLevel
    private let sink: any LogSink
    private let redactionPolicy: any RedactionPolicy

    init(
        minimumLevel: LogLevel,
        sink: any LogSink,
        redactionPolicy: any RedactionPolicy = DefaultRedactionPolicy()
    ) {
        self.minimumLevel = minimumLevel
        self.sink = sink
        self.redactionPolicy = redactionPolicy
    }

    func log(
        level: LogLevel,
        category: LogCategory,
        eventName: String,
        message: String,
        metadata: [String: String]?
    ) {
        guard level >= minimumLevel else { return }
        let entry = LogEntry(
            timestamp: Date(),
            level: level,
            category: category,
            eventName: eventName,
            message: message,
            metadata: redactionPolicy.redact(metadata: metadata ?? [:])
        )
        sink.write(entry)
    }

    static func makeForCurrentBuild(
        featureFlags: any FeatureFlagsProvider = LocalFeatureFlagsProvider()
    ) -> DefaultAppLogger {
        let console = ConsoleLogSink()
        let remoteSink: any RemoteAnalyticsLogSink = if featureFlags.isEnabled(.enableFirebaseAnalytics) {
            FirebaseAnalyticsLogSink(isCollectionEnabled: FirebaseBootstrap.isAnalyticsCollectionEnabled)
        } else {
            NoOpRemoteAnalyticsLogSink()
        }
        let crashlyticsSink: any LogSink = if featureFlags.isEnabled(.enableFirebaseCrashlytics) {
            FirebaseCrashlyticsLogSink(isCollectionEnabled: FirebaseBootstrap.isCrashlyticsCollectionEnabled)
        } else {
            NoOpLogSink()
        }
        let sink = CompositeLogSink(sinks: [
            console,
            FilteredLogSink(minimumLevel: .info, wrapped: remoteSink),
            crashlyticsSink
        ])
        #if DEBUG
        return DefaultAppLogger(minimumLevel: .debug, sink: sink)
        #else
        return DefaultAppLogger(minimumLevel: .info, sink: sink)
        #endif
    }
}
