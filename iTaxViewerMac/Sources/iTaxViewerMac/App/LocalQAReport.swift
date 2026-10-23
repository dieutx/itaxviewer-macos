import Foundation

/// Opt-in local build diagnostics. No XML, taxpayer fields or full source paths
/// are recorded. Ordinary launches never create a report or emit these events.
enum LocalQAReport {
    private struct Event: Codable {
        let file: String
        let stage: String
    }
    private static var events: [Event] = []
    private static let lock = NSLock()

    static func record(file: String, stage: String) {
        let arguments = CommandLine.arguments
        guard let index = arguments.firstIndex(of: "--qa-open-report"),
              arguments.indices.contains(index + 1) else { return }
        let destination = URL(fileURLWithPath: arguments[index + 1])
        guard destination.pathExtension == "json" else { return }
        lock.lock()
        defer { lock.unlock() }
        events.append(Event(file: (file as NSString).lastPathComponent, stage: stage))
        if let data = try? JSONEncoder().encode(events) {
            try? data.write(to: destination, options: .atomic)
        }
    }
}
