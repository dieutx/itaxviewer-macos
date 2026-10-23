import Foundation

/// Preserve fields outside a reviewed declaration's map as explicitly labelled
/// source data. This does not assign official labels to unknown XML fields.
struct SupplementalFormData {
    let document: TaxDocument
    let spec: FormSpec

    func render() -> String {
        guard let main = document.root.firstDescendant(named: "CTieuTKhaiChinh") else { return "" }
        var consumed: Set<ObjectIdentifier> = []
        func context(_ name: String?) -> XMLNode? {
            switch name {
            case "ktru": return main.firstChild(named: "NVuKhauTruThue")
            case "qtoan": return main.firstChild(named: "NVuQToanThay")
            case "ttkthue": return document.root.firstDescendant(named: "TTinTKhaiThue")
            default: return main
            }
        }
        func mark(_ node: XMLNode?) {
            guard let node else { return }
            for leaf in node.leaves(limit: .max) { consumed.insert(ObjectIdentifier(leaf)) }
        }
        func markValue(_ value: FormSpec.Value) { mark(context(value.root)?.node(atLocalPath: value.path)) }
        for row in spec.rows { for value in row.values { markValue(value) } }
        for field in spec.headerFields ?? [] {
            mark(context(field.root)?.node(atLocalPath: field.path))
            if let path = field.suffixPath { mark(context(field.root)?.node(atLocalPath: path)) }
            for part in field.parts ?? [] { mark(context(part.root ?? field.root)?.node(atLocalPath: part.path)) }
        }
        for field in spec.extraFields ?? [] { mark(main.node(atLocalPath: field.path)) }
        for field in spec.conditionalHeaderFields ?? [] {
            let node = main.node(atLocalPath: field.path)
            let raw = node?.trimmedValue ?? ""
            if field.equals.contains(raw) || ["true", "false", "0", "1", ""].contains(raw) { mark(node) }
        }
        for row in spec.tableRows ?? [] {
            for cell in row.cells {
                if let value = cell.value { markValue(value) }
                for choice in cell.choices ?? [] {
                    let node = main.node(atLocalPath: choice.path)
                    if choice.equals.contains(node?.trimmedValue ?? "") { mark(node) }
                }
            }
        }
        for table in spec.repeatedTables ?? [] {
            let parts = table.recordPath.split(separator: "/").map(String.init)
            guard let name = parts.last else { continue }
            let parentPath = parts.dropLast().joined(separator: "/")
            let parent = parentPath.isEmpty ? main : main.node(atLocalPath: parentPath)
            for record in parent?.children(named: name) ?? [] {
                for column in table.columns where column.source != "@position" { mark(record.node(atLocalPath: column.source)) }
            }
            for total in table.totals ?? [] { mark(main.node(atLocalPath: total.source)) }
        }
        var rows = ""
        func walk(_ node: XMLNode, path: String) {
            guard node.localName != "Signature" else { return }
            if node.children.isEmpty {
                if !consumed.contains(ObjectIdentifier(node)), !node.trimmedValue.isEmpty {
                    rows += "<tr><td>\(VietnameseFormat.htmlEscape(path))</td><td>\(VietnameseFormat.htmlEscape(node.trimmedValue))</td></tr>"
                }
            } else {
                var indices: [String: Int] = [:]
                for child in node.children {
                    let index = indices[child.localName, default: 0] + 1
                    indices[child.localName] = index
                    walk(child, path: path + "/" + child.localName + "[\(index)]")
                }
            }
        }
        walk(main, path: "CTieuTKhaiChinh")
        guard !rows.isEmpty else { return "" }
        return "<section class=\"form-unmapped\"><h3>Dữ liệu XML bổ sung ngoài bố cục đã đối chiếu</h3>"
            + "<table class=\"data-table\"><thead><tr><th>Đường dẫn dữ liệu</th><th>Giá trị</th></tr></thead><tbody>"
            + rows + "</tbody></table></section>"
    }
}
