import Foundation

public enum XMLInspectionError: Error, LocalizedError, Equatable {
    case emptyDocument
    case documentTooLarge(limit: Int)
    case doctypeForbidden
    case malformed(String)
    case nestingTooDeep
    case tooManyNodes(limit: Int)

    public var errorDescription: String? {
        switch self {
        case .emptyDocument:
            return "Tệp rỗng hoặc không có nội dung XML."
        case .documentTooLarge(let limit):
            return "Tệp quá lớn (giới hạn \(limit / 1_048_576) MB)."
        case .tooManyNodes(let limit):
            return "Tệp có quá nhiều phần tử XML (giới hạn \(limit))."
        case .doctypeForbidden:
            return "Tệp chứa DOCTYPE/ENTITY. Vì lý do an toàn, tài liệu có DTD không được mở."
        case .malformed(let detail):
            return "Tệp hồ sơ không đúng định dạng. \(detail)"
        case .nestingTooDeep:
            return "Cấu trúc XML lồng quá sâu."
        }
    }
}

public struct XMLSecurityLimits {
    public var maxBytes: Int
    public var maxDepth: Int
    public var maxNodes: Int

    public init(maxBytes: Int = 64 * 1024 * 1024,
                maxDepth: Int = 256,
                maxNodes: Int = 500_000) {
        self.maxBytes = maxBytes
        self.maxDepth = maxDepth
        self.maxNodes = maxNodes
    }
}

/// Hardened XML loader.
///
/// Security properties (all verified by tests):
/// * external entity resolution disabled;
/// * any DOCTYPE / ENTITY declaration is rejected before parsing (XXE / billion laughs);
/// * size, depth and node-count limits;
/// * namespace-aware parsing;
/// * UTF-8, UTF-16LE/BE with BOM and XML-declared encodings handled by Foundation.
public enum SecureXMLParser {

    public static func parse(data: Data, limits: XMLSecurityLimits = .init()) throws -> XMLNode {
        guard !data.isEmpty else { throw XMLInspectionError.emptyDocument }
        guard data.count <= limits.maxBytes else {
            throw XMLInspectionError.documentTooLarge(limit: limits.maxBytes)
        }
        try rejectDoctype(in: data)

        let delegate = TreeBuilderDelegate(limits: limits)
        let parser = XMLParser(data: data)
        parser.shouldProcessNamespaces = true
        parser.shouldReportNamespacePrefixes = true
        parser.shouldResolveExternalEntities = false
        parser.delegate = delegate

        guard parser.parse(), let root = delegate.root else {
            if let failure = delegate.failure { throw failure }
            let detail = parser.parserError?.localizedDescription ?? "Không thể đọc XML."
            throw XMLInspectionError.malformed(detail)
        }
        return root
    }

    public static func parse(url: URL, limits: XMLSecurityLimits = .init()) throws -> XMLNode {
        let data: Data
        do {
            data = try Data(contentsOf: url, options: [.mappedIfSafe])
        } catch {
            throw XMLInspectionError.malformed(error.localizedDescription)
        }
        return try parse(data: data, limits: limits)
    }

    /// Rejects any DTD/ENTITY marker regardless of its position in the file.
    ///
    /// Scanning only the first megabyte was bypassable with a large comment or
    /// processing instruction before the DOCTYPE (both are legal before the
    /// root element). The raw-byte search covers UTF-8 and UTF-16LE/BE without
    /// allocating a copy of a 64 MB document.
    static func rejectDoctype(in data: Data) throws {
        let markers = ["<!DOCTYPE", "<!ENTITY"]
        for marker in markers {
            for bytes in encodings(of: marker) {
                if data.range(of: Data(bytes)) != nil {
                    throw XMLInspectionError.doctypeForbidden
                }
            }
        }
    }

    /// ASCII, UTF-16LE and UTF-16BE byte patterns for a marker, in both cases.
    private static func encodings(of marker: String) -> [[UInt8]] {
        var result: [[UInt8]] = []
        for variant in [marker, marker.lowercased()] {
            let ascii = Array(variant.utf8)
            result.append(ascii)
            var le: [UInt8] = []
            var be: [UInt8] = []
            for byte in ascii {
                le.append(byte)
                le.append(0)
                be.append(0)
                be.append(byte)
            }
            result.append(le)
            result.append(be)
        }
        return result
    }
}

private final class TreeBuilderDelegate: NSObject, XMLParserDelegate {
    let limits: XMLSecurityLimits
    var root: XMLNode?
    var stack: [XMLNode] = []
    var nodeCount = 0
    var failure: XMLInspectionError?

    init(limits: XMLSecurityLimits) {
        self.limits = limits
    }

    func parser(_ parser: XMLParser,
                didStartElement elementName: String,
                namespaceURI: String?,
                qualifiedName qName: String?,
                attributes attributeDict: [String: String]) {
        guard failure == nil else { return }
        nodeCount += 1
        if nodeCount > limits.maxNodes {
            failure = .tooManyNodes(limit: limits.maxNodes)
            parser.abortParsing()
            return
        }
        if stack.count >= limits.maxDepth {
            failure = .nestingTooDeep
            parser.abortParsing()
            return
        }
        var attributes: [String: String] = [:]
        for (key, value) in attributeDict {
            // Strip namespace prefixes from attribute keys for convenient lookup.
            let local = key.split(separator: ":").last.map(String.init) ?? key
            attributes[local] = value
        }
        let prefix = qName?.split(separator: ":").first.map(String.init)
        let localName = elementName.split(separator: ":").last.map(String.init) ?? elementName
        let node = XMLNode(name: qName ?? elementName,
                           localName: localName,
                           prefix: prefix,
                           namespaceURI: namespaceURI,
                           attributes: attributes,
                           parent: stack.last)
        if let parent = stack.last {
            parent.append(child: node)
        } else {
            root = node
        }
        stack.append(node)
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        stack.last?.appendText(string)
    }

    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        if let s = String(data: CDATABlock, encoding: .utf8) {
            stack.last?.appendText(s)
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        if !stack.isEmpty { stack.removeLast() }
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        if failure == nil {
            failure = .malformed(parseError.localizedDescription)
        }
    }
}
