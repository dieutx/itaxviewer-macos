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
    case badResponse(Int)
    case invalidPayload

    public var errorDescription: String? {
        switch self {
        case .badResponse(let code):
            return "Máy chủ cập nhật trả về mã \(code)."
        case .invalidPayload:
            return "Không đọc được thông tin bản phát hành."
        }
    }
}

/// Minimal, privacy-preserving release check against the public GitHub
/// releases API.
///
/// Only the application version is sent in the user agent. No document
/// content, taxpayer data, identifiers or telemetry are transmitted, and the
/// response is never cached to disk. This is the only network request the app
/// makes; it can be disabled in Settings/UserDefaults (`itax.updateCheck.disabled`).
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
        var request = URLRequest(url: URL(string: "https://api.github.com/repos/\(owner)/\(repository)/releases/latest")!)
        request.httpMethod = "GET"
        request.timeoutInterval = 12
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("iTaxViewerMac/\(currentVersion)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw UpdateError.invalidPayload
        }
        if http.statusCode == 404 { return nil }
        guard http.statusCode == 200 else {
            throw UpdateError.badResponse(http.statusCode)
        }
        guard let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tag = object["tag_name"] as? String,
              let urlString = object["html_url"] as? String,
              let pageURL = URL(string: urlString) else {
            throw UpdateError.invalidPayload
        }
        let version = Self.normalizedVersion(tag)
        guard AppVersion.isNewer(version, than: currentVersion) else { return nil }
        let publishedAt = (object["published_at"] as? String).flatMap(Self.isoDate)
        return AppRelease(version: version,
                          pageURL: pageURL,
                          notes: object["body"] as? String,
                          publishedAt: publishedAt)
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
