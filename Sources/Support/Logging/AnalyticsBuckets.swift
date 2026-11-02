import Foundation

enum AnalyticsBuckets {
    static func bpmBucket(_ bpm: Int) -> String {
        let lower = (max(0, bpm) / 10) * 10
        return "\(lower)_\(lower + 9)"
    }

    static func confidenceBucket(_ confidence: Double) -> String {
        if confidence < 0.4 { return "low" }
        if confidence < 0.7 { return "medium" }
        return "high"
    }

    static func durationBucket(seconds: TimeInterval) -> String {
        if seconds < 10 { return "under_10s" }
        if seconds < 30 { return "10_30s" }
        if seconds < 120 { return "30_120s" }
        return "over_120s"
    }
}
