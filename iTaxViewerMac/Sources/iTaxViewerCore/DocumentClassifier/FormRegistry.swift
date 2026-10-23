import Foundation

public struct FormSpec: Codable, Identifiable {
    public struct Value: Codable {
        public let root: String?
        public let path: String
    }

    public struct Row: Codable {
        public let stt: String
        public let label: String
        public let indicator: String
        public let codes: [String]
        public let values: [Value]
        public let kind: String

        public var isSection: Bool { kind == "section" }
        public var isCheckbox: Bool { kind == "checkbox" }
    }

    public let displayCode: String
    public let maTKhai: String
    public let versions: [String]
    public let sourceTemplate: String
    public let columns: [String]?
    public let rows: [Row]

    public var id: String { displayCode }
}

public struct FormRegistry: Decodable {
    public struct SourceInfo: Decodable {
        public let application: String
        public let registryFile: String
        public let entries: Int
        public let formCodes: Int
    }

    public struct SupportedForm: Decodable {
        public let displayCode: String
        public let maTKhai: String
        public let versions: [String]
        public let spec: String
        public let orientation: String
        public let title: String

        public var isLandscape: Bool { orientation == "1" }
    }

    public struct CodeInfo: Decodable {
        public let displayCode: String?
        public let latestVersion: String?
        public let versions: [String]
        public let orientation: String
        public let loai: [String]
    }

    public let schemaVersion: Int
    public let source: SourceInfo
    public let supported: [SupportedForm]
    public let codes: [String: CodeInfo]
    private let specs: [String: FormSpec]

    enum CodingKeys: String, CodingKey {
        case schemaVersion, source, supported, codes
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try c.decode(Int.self, forKey: .schemaVersion)
        source = try c.decode(SourceInfo.self, forKey: .source)
        supported = try c.decode([SupportedForm].self, forKey: .supported)
        codes = try c.decode([String: CodeInfo].self, forKey: .codes)
        specs = [:]
    }

    public static func bundled() throws -> FormRegistry {
        guard let url = Bundle.module.url(forResource: "form-registry", withExtension: "json") else {
            throw DocumentError.registryMissing("form-registry.json")
        }
        let data = try Data(contentsOf: url)
        let base = try JSONDecoder().decode(FormRegistry.self, from: data)
        let specURL = Bundle.module.url(forResource: "form-specs", withExtension: "json")
        let specs: [String: FormSpec] = try specURL.map { url -> [String: FormSpec] in
            let list = try JSONDecoder().decode([FormSpec].self, from: Data(contentsOf: url))
            return Dictionary(uniqueKeysWithValues: list.map { ($0.displayCode, $0) })
        } ?? [:]
        return base.withSpecs(specs)
    }

    private init(schemaVersion: Int, source: SourceInfo, supported: [SupportedForm],
                 codes: [String: CodeInfo], specs: [String: FormSpec]) {
        self.schemaVersion = schemaVersion
        self.source = source
        self.supported = supported
        self.codes = codes
        self.specs = specs
    }

    private func withSpecs(_ specs: [String: FormSpec]) -> FormRegistry {
        FormRegistry(schemaVersion: schemaVersion, source: source, supported: supported,
                     codes: codes, specs: specs)
    }

    public func spec(for displayCode: String) -> FormSpec? { specs[displayCode] }

    public func codeInfo(_ code: String) -> CodeInfo? { codes[code] }

    /// Legacy `maTKhai` values that were renumbered to a new code without any
    /// change to the printed form. The 01/GTGT declaration moved from `01`
    /// (TT 156/2013, XML 2.0.6–2.6.2) to `842` (TT 80/2021, 2.5.1+); the
    /// indicator tags are identical, verified against real 2.1.2 and 2.5.0
    /// files. Only map codes whose structure has actually been checked.
    private static let legacyCodeAliases: [String: String] = [
        "01": "842"
    ]

    /// Mirrors the original lookup: exact code, then version-insensitive match,
    /// then a verified legacy-code alias, and the historical version rewrite
    /// for forms 42/43/44/103.
    public func resolve(code: String, version: String?, filingType: String?) -> SupportedForm? {
        let effectiveVersion = normalizedVersion(code: code, version: version)
        if let exact = supported.first(where: { $0.maTKhai == code && $0.versions.contains(effectiveVersion ?? "") }) {
            return exact
        }
        if let direct = supported.first(where: { $0.maTKhai == code }) {
            return direct
        }
        if let alias = Self.legacyCodeAliases[code] {
            return supported.first { $0.maTKhai == alias }
        }
        return nil
    }

    public func normalizedVersion(code: String, version: String?) -> String? {
        guard let version else { return nil }
        if ["42", "43", "44", "103"].contains(code), version != "2.0.5", version != "2.0.8" {
            return "2.0.0"
        }
        return version
    }
}
