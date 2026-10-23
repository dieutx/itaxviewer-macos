import Foundation

/// A published release of the application.
public struct AppRelease: Equatable, Sendable {
    public let version: String
    public let pageURL: URL
    public let notes: String?
    public let publishedAt: Date?

    public init(version: String, pageURL: URL, notes: String? = nil, publishedAt: Date? = nil) {
        self.version = version
        self.pageURL = pageURL
        self.notes = notes
        self.publishedAt = publishedAt
    }
}

public enum UpdateError: Error, LocalizedError {
    case offlineMode
    case badResponse(Int)
    case invalidPayload

    public var errorDescription: String? {
        switch self {
        case .offlineMode:
            return "Bản dựng này hoạt động ngoại tuyến; kiểm tra cập nhật qua mạng đã tắt."
        case .badResponse(let code):
            return "Máy chủ cập nhật trả về mã \(code)."
        case .invalidPayload:
            return "Không đọc được thông tin bản phát hành."
        }
    }
}

/// Compatibility surface retained for version parsing. This offline build
/// rejects release checks before constructing a request or contacting a host.
public struct GitHubReleaseClient: Sendable {
    public let owner: String
    public let repository: String
    public let session: URLSession

    public init(owner: String = "dieutx",
                repository: String = "itaxviewer-macos",
                session: URLSession = .shared) {
        self.owner = owner
        self.repository = repository
        self.session = session
    }

    public func latestRelease(currentVersion: String) async throws -> AppRelease? {
        throw UpdateError.offlineMode
    }

    static func normalizedVersion(_ raw: String) -> String {
        var value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if value.lowercased().hasPrefix("v") { value.removeFirst() }
        return value
    }

    static func isoDate(_ raw: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: raw)
    }
}

/// Semantic-ish version comparison used by the update check.
public enum AppVersion {
    /// Returns true when `remote` is a strictly newer dotted numeric version.
    /// Pre-release suffixes ("2.0.0-beta.1") compare by their numeric core,
    /// which is enough for the release channel used by this project.
    public static func isNewer(_ remote: String, than local: String) -> Bool {
        let r = components(remote)
        let l = components(local)
        let count = max(r.count, l.count)
        for index in 0..<count {
            let rv = index < r.count ? r[index] : 0
            let lv = index < l.count ? l[index] : 0
            if rv != lv { return rv > lv }
        }
        return false
    }

    private static func components(_ value: String) -> [Int] {
        let core = value.split(separator: "-", maxSplits: 1).first.map(String.init) ?? value
        return core.split(separator: ".").map { Int($0.prefix { $0.isNumber }) ?? 0 }
    }
}
