import Foundation

/// Routing facts from the Windows registries. Presence here means recognised,
/// not that an official layout has been recreated or visually verified.
public struct DocumentRegistryEntry: Decodable {
    public let kind: String
    public let registry: String
    public let root: String
    public let id: String
    public let version: String
    public let orientation: String

    func matches(root name: String) -> Bool {
        switch root {
        case "THONGBAO...":
            return ["THONGBAO", "THONG_BAO", "TBAO_TKHOAN_NH", "TBAO_TKHOAN_NT", "TBAO_NGUNG"].contains(name)
        case "XACNHAN_*": return ["XACNHAN_THUE", "XACNHAN_NVTHUE"].contains(name)
        case "*:Envelope": return name == "Envelope"
        default: return root == name
        }
    }

    static func bundled() throws -> [DocumentRegistryEntry] {
        guard let url = Bundle.module.url(forResource: "document-registry", withExtension: "json") else {
            throw DocumentError.registryMissing("document-registry.json")
        }
        return try JSONDecoder().decode([DocumentRegistryEntry].self, from: Data(contentsOf: url))
    }
}
