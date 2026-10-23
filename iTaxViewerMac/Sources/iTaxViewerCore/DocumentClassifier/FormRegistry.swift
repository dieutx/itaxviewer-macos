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
        public let unit: String?

        public var isSection: Bool { kind == "section" }
        public var isCheckbox: Bool { kind == "checkbox" }
    }

    public struct HeaderField: Codable {
        public let code: String
        public let label: String
        public let root: String?
        public let path: String
        public let suffixPath: String?
        public let suffixFormat: String?
    }

    public struct ExtraField: Codable {
        public let code: String
        public let label: String
        public let path: String
        public let format: String
    }

    public struct RepeatedTable: Codable {
        public struct Column: Codable {
            public let label: String
            public let source: String
            public let format: String
        }
        public let title: String
        public let recordPath: String
        public let columns: [Column]
        public let totals: [Column]
    }

    public struct TableCell: Codable {
        public struct Choice: Codable {
            public let path: String
            public let equals: [String]
            public let text: String
        }
        public let text: String
        public let value: Value?
        public let rowspan: Int?
        public let colspan: Int?
        public let bold: Bool?
        public let choices: [Choice]?
    }

    public struct TableRow: Codable {
        public let cells: [TableCell]
    }

    public let displayCode: String
    public let maTKhai: String
    public let versions: [String]
    public let sourceTemplate: String
    public let columns: [String]?
    public let rows: [Row]
    public let headerFields: [HeaderField]?
    public let extraFields: [ExtraField]?
    public let repeatedTables: [RepeatedTable]?
    public let verificationStatus: String?
    public let tableHeaders: [TableCell]?
    public let tableRows: [TableRow]?

    public var id: String { maTKhai }
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
    private let documentEntries: [DocumentRegistryEntry]

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
        documentEntries = []
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
            return Dictionary(uniqueKeysWithValues: list.map { ($0.maTKhai, $0) })
        } ?? [:]
        return base.withSpecs(specs, documents: try DocumentRegistryEntry.bundled())
    }

    private init(schemaVersion: Int, source: SourceInfo, supported: [SupportedForm],
                 codes: [String: CodeInfo], specs: [String: FormSpec], documents: [DocumentRegistryEntry]) {
        self.schemaVersion = schemaVersion
        self.source = source
        self.supported = supported
        self.codes = codes
        self.specs = specs
        self.documentEntries = documents
    }

    private func withSpecs(_ specs: [String: FormSpec], documents: [DocumentRegistryEntry]) -> FormRegistry {
        FormRegistry(schemaVersion: schemaVersion, source: source, supported: supported,
                     codes: codes, specs: specs, documents: documents)
    }

    public func documentEntry(root: String, code: String?, version: String?) -> DocumentRegistryEntry? {
        guard let code, let version else { return nil }
        return documentEntries.first { $0.matches(root: root) && $0.id == code && $0.version == version }
    }

    /// Kept for callers asking for the primary layout; classification always
    /// resolves by internal code, since multiple layouts share a display code.
    public func spec(for displayCode: String) -> FormSpec? {
        supported.first { $0.displayCode == displayCode }.flatMap { specs[$0.maTKhai] }
    }

    public func spec(for form: SupportedForm) -> FormSpec? { specs[form.maTKhai] }

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
            // Newly recovered layouts are version-bound; unknown revisions must
            // retain all data rather than applying an unverified field map.
            if specs[code]?.verificationStatus != nil { return nil }
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
