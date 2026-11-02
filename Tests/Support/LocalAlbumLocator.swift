import Foundation

/// Resolves gitignored, locally owned album folders for dev-only analyzer tests.
enum LocalAlbumLocator {
    static let supportedExtensions = ["mp3", "m4a", "wav", "aiff", "aif", "caf"]

    static var repoRoot: URL {
        var url = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        let fileManager = FileManager.default
        for _ in 0..<8 {
            if fileManager.fileExists(atPath: url.appendingPathComponent("project.yml").path)
                || fileManager.fileExists(atPath: url.appendingPathComponent("RPMBuddy.xcodeproj").path) {
                return url
            }
            url.deleteLastPathComponent()
        }
        return URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    static func directory(named albumName: String) -> URL? {
        if let configured = ProcessInfo.processInfo.environment["RPMBUDDY_LOCAL_AUDIO_DIR"] {
            let url = URL(fileURLWithPath: configured, isDirectory: true)
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }

        let candidates = [
            repoRoot.appendingPathComponent("local-test-media/\(albumName)", isDirectory: true),
            repoRoot.appendingPathComponent("local-test-media/albums/\(albumName)", isDirectory: true),
            repoRoot.appendingPathComponent(albumName, isDirectory: true),
        ]
        return candidates.first { FileManager.default.fileExists(atPath: $0.path) }
    }

    static func audioFiles(in directory: URL) -> [URL] {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ) else {
            return []
        }
        return files
            .filter { supportedExtensions.contains($0.pathExtension.lowercased()) }
            .sorted {
                $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending
            }
    }

    static func firstAudioFile(in directory: URL, matching substring: String) -> URL? {
        audioFiles(in: directory).first {
            $0.lastPathComponent.localizedCaseInsensitiveContains(substring)
        }
    }
}
