import Foundation

/// A small, namespace-aware document tree built on top of Foundation's XMLParser.
/// It deliberately exposes only what the renderer needs; it is not a general DOM.
public final class XMLNode {
    public let name: String
    public let localName: String
    public let prefix: String?
    public let namespaceURI: String?
    public private(set) var attributes: [String: String]
    public private(set) weak var parent: XMLNode?
    public private(set) var children: [XMLNode] = []
    public private(set) var text: String = ""

    init(name: String,
         localName: String,
         prefix: String?,
         namespaceURI: String?,
         attributes: [String: String],
         parent: XMLNode?) {
        self.name = name
        self.localName = localName
        self.prefix = prefix
        self.namespaceURI = namespaceURI
        self.attributes = attributes
        self.parent = parent
    }

    func append(child: XMLNode) {
        children.append(child)
    }

    func appendText(_ value: String) {
        text += value
    }

    public var stringValue: String {
        if children.isEmpty { return text }
        return text + children.map(\.stringValue).joined()
    }

    public var trimmedValue: String {
        stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public func attribute(_ key: String) -> String? {
        if let v = attributes[key] { return v }
        // XML attribute names are case-sensitive, but tax files in the wild
        // use both `Id` and `id`; mirror the original application's tolerance.
        return attributes.first { $0.key.caseInsensitiveCompare(key) == .orderedSame }?.value
    }

    public func children(named name: String) -> [XMLNode] {
        children.filter { $0.localName == name }
    }

    public func firstChild(named name: String) -> XMLNode? {
        children.first { $0.localName == name }
    }

    /// Depth-first search for the first descendant with a matching local name.
    public func firstDescendant(named name: String) -> XMLNode? {
        if localName == name { return self }
        for child in children {
            if let found = child.firstDescendant(named: name) { return found }
        }
        return nil
    }

    public func descendants(named name: String, limit: Int = 10_000) -> [XMLNode] {
        var result: [XMLNode] = []
        func walk(_ node: XMLNode) {
            if result.count >= limit { return }
            if node.localName == name { result.append(node) }
            for child in node.children {
                walk(child)
                if result.count >= limit { return }
            }
        }
        walk(self)
        return result
    }

    /// Resolve a slash separated path of local names below this node.
    public func node(atLocalPath path: String) -> XMLNode? {
        var current: XMLNode? = self
        for part in path.split(separator: "/") where !part.isEmpty {
            current = current?.firstChild(named: String(part))
            if current == nil { return nil }
        }
        return current
    }

    /// All leaf elements in document order (elements without element children).
    public func leaves(limit: Int = 5_000) -> [XMLNode] {
        var result: [XMLNode] = []
        func walk(_ node: XMLNode) {
            if result.count >= limit { return }
            if node.children.isEmpty {
                result.append(node)
            } else {
                for child in node.children { walk(child) }
            }
        }
        walk(self)
        return result
    }
}
