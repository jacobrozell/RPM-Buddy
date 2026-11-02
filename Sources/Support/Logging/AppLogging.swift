import Foundation

enum AppLogging {
    static let logger: any AppLogger = DefaultAppLogger.makeForCurrentBuild()
}
