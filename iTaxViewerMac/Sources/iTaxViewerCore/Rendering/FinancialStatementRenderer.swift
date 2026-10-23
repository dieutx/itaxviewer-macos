import Foundation

/// Independently authored financial-statement layout. Field facts and selected
/// template hashes are recorded in docs/reverse-engineering/forms/{701,702,1254}.
/// No XSLT, script, stylesheet or vendor asset is executed or bundled.
struct FinancialStatementRenderer {
    let document: TaxDocument
    let spec: FormSpec

    static func supports(document: TaxDocument) -> Bool {
        switch (document.metadata.formCode, document.metadata.formVersion) {
        case ("701", "2.3.5"), ("702", "2.3.5"), ("1254", "2.9.0"): return true
        default: return false
        }
    }

    func render() -> String? {
        guard Self.supports(document: document), spec.maTKhai == document.metadata.formCode,
              spec.versions.contains(document.metadata.formVersion ?? ""),
              let rows = spec.tableRows else { return nil }
        let main = document.root.firstDescendant(named: "CTieuTKhaiChinh")
        let common = document.root.firstDescendant(named: "TTinTKhaiThue")
        var represented: Set<ObjectIdentifier> = []
        func read(_ path: String, mainField: Bool = true) -> String {
            guard let node = (mainField ? main : common)?.node(atLocalPath: path) else { return "" }
            represented.insert(ObjectIdentifier(node))
            return node.trimmedValue
        }
        func esc(_ value: String) -> String { VietnameseFormat.htmlEscape(value) }
        let modern = spec.maTKhai == "1254"
        let basis = modern
            ? "Kèm theo Thông tư số 24/2024/TT-BTC ngày 17/4/2024 của Bộ trưởng Bộ Tài chính"
            : "Ban hành theo Thông tư số 107/2017/TT-BTC ngày 10/10/2017 của Bộ Tài chính"
        var html = """
        <style>
        .bctc { font-size: 10pt; }
        .bctc .bctc-heading { width: 100%; border-collapse: collapse; margin-bottom: 12px; }
        .bctc-heading td { width: 50%; text-align: center; vertical-align: top; padding: 4px; }
        .bctc .bctc-title { text-align: center; font-size: 15pt; font-weight: bold; margin: 12px 0 6px; }
        .bctc .bctc-period { text-align: center; margin-bottom: 10px; }
        .bctc .bctc-identity p { margin: 3px 0; }
        .bctc .bctc-unit { text-align: right; margin: 8px 0; }
        .bctc .tax-table { font-size: 10pt; }
        .bctc .tax-table td, .bctc .tax-table th { padding: 3px 4px; }
        .bctc .bctc-signatures { width: 100%; margin-top: 18px; border-collapse: collapse; break-inside: avoid; }
        .bctc-signatures td { width: 33.33%; text-align: center; vertical-align: top; padding: 5px; }
        .bctc .bctc-signature-name { min-height: 45px; padding-top: 30px; }
        .bctc .bctc-notes { font-size: 9pt; margin-top: 10px; }
        </style><section class="bctc">
        """
        let entity = read("NNT/tenNNT", mainField: false)
        html += "<table class=\"bctc-heading\"><tr><td>"
        if modern {
            html += "<b>\(esc(read("tenCoQuanCapTren").uppercased(with: Locale(identifier: "vi_VN"))))</b><br>"
            html += "<b>\(esc(entity.uppercased(with: Locale(identifier: "vi_VN"))))</b>"
        }
        html += "</td><td><b>CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM</b><br><b>Độc lập-Tự do-Hạnh phúc</b><br>-------------------------</td></tr>"
        html += "<tr><td></td><td>Mẫu số: <b>\(esc(spec.displayCode))</b><br><small>(\(esc(basis)))</small></td></tr></table>"
        html += "<div class=\"bctc-title\">BÁO CÁO TÌNH HÌNH TÀI CHÍNH</div>"
        if spec.maTKhai == "702" {
            html += "<p class=\"bctc-period\">(Dành cho đơn vị lập báo cáo tài chính theo mẫu đơn giản)</p>"
        }
        html += "<div class=\"bctc-period\">Tại ngày \(esc(dateWords(read("TKhaiThue/KyKKhaiThue/kyKKhaiDenNgay", mainField: false))))</div>"
        if !modern {
            html += "<div class=\"bctc-identity\">"
            let identity = [
                ("01", "Tên người nộp thuế:", "NNT/tenNNT"),
                ("02", "Mã số thuế:", "NNT/mst"),
                ("03", "Địa chỉ:", "NNT/dchiNNT"),
                ("04", "Quận/Huyện:", "NNT/tenHuyenNNT"),
                ("05", "Tỉnh/Thành phố:", "NNT/tenTinhNNT"),
                ("06", "Điện thoại:", "NNT/dthoaiNNT"),
                ("07", "Fax:", "NNT/faxNNT"),
                ("08", "E-mail:", "NNT/emailNNT")
            ]
            for (code, label, path) in identity {
                html += "<p><b>[\(code)] \(label)</b> \(esc(read(path, mainField: false)))</p>"
            }
            let audited = ["true", "1"].contains(read("bctcDaKiemToan"))
            html += "<p>BCTC đã được kiểm toán: [\(audited ? "x" : "")]  Ý kiến kiểm toán: \(esc(read("tenYKienKToan")))</p></div>"
        }
        html += "<div class=\"bctc-unit\">Đơn vị tính: \(modern ? "Đồng" : "đồng") Việt Nam</div>"
        html += "<table class=\"tax-table bctc-table\"><colgroup><col style=\"width:6%\"><col style=\"width:40%\"><col style=\"width:9%\"><col style=\"width:11%\"><col style=\"width:17%\"><col style=\"width:17%\"></colgroup><thead><tr>"
        for cell in spec.tableHeaders ?? [] { html += "<th>\(esc(cell.text))</th>" }
        html += "</tr></thead><tbody>"
        for row in rows {
            html += "<tr>"
            for cell in row.cells {
                var value = cell.text
                var attributes = ""
                if let span = cell.rowspan { attributes += " rowspan=\"\(span)\"" }
                if let span = cell.colspan { attributes += " colspan=\"\(span)\"" }
                if let field = cell.value {
                    let raw = read(field.path)
                    if field.path.hasPrefix("ThuyetMinh/") {
                        value += raw
                    } else {
                        value += VietnameseFormat.number(raw)
                        attributes += " class=\"r\""
                    }
                }
                let content = cell.bold == true ? "<b>\(esc(value))</b>" : esc(value)
                html += "<td\(attributes)>\(content)</td>"
            }
            html += "</tr>"
        }
        html += "</tbody></table>"
        if !modern {
            // Official form notes, recorded as factual text in the matching specs.
            html += """
            <div class="bctc-notes"><b>Ghi chú:</b>
            <p>(1) Số liệu trong các chỉ tiêu có dấu (*) được ghi bằng số âm dưới hình thức ghi trong ngoặc đơn (...).</p>
            <p>(2) Các chỉ tiêu không có số liệu thì không phải báo cáo nhưng không được đánh lại "Mã số".</p>
            <p>(3) Doanh nghiệp có kỳ kế toán năm là năm dương lịch (X) thì "Số cuối năm" có thể ghi là "31.12.X"; "Số đầu năm" có thể ghi là "01.01.X".</p>
            <p>(4) Đối với trường hợp thuê dịch vụ làm kế toán, làm kế toán trưởng thì phải ghi rõ số Giấy chứng nhận đăng ký hành nghề dịch vụ kế toán, tên đơn vị cung cấp dịch vụ kế toán.</p></div>
            """
        }
        let prefix = modern ? "PhanKy/" : ""
        let chiefPath = spec.maTKhai == "702" ? "thuTruongdonVi" : prefix + "thuTruongDonVi"
        let people = [read(prefix + "nguoiLapBieu"), read(prefix + "keToanTruong"), read(chiefPath)]
        let signingDate = read(prefix + "ngayLap")
        html += "<table class=\"bctc-signatures\"><tr><td></td><td></td><td>Lập\(modern ? "," : "") ngày \(esc(dateWords(signingDate)))</td></tr><tr>"
        let labels = modern ? ["Người lập biểu", "Kế toán trưởng", "THỦ TRƯỞNG ĐƠN VỊ"]
                            : ["NGƯỜI LẬP BIỂU", "KẾ TOÁN TRƯỞNG", "NGƯỜI ĐẠI DIỆN THEO PHÁP LUẬT"]
        for index in 0..<3 {
            let hint = modern ? (index == 2 ? "(Ký, họ tên, đóng dấu)" : "(Ký, họ tên)")
                              : (index == 2 ? "(Ký, Ghi rõ họ tên, Đóng dấu)" : "(Ký, Ghi rõ họ tên)")
            html += "<td><b>\(labels[index])</b><br><i>\(hint)</i><div class=\"bctc-signature-name\">\(esc(people[index]))</div></td>"
        }
        html += "</tr></table>"
        if !document.signatures.isEmpty { html += "<p>Chữ ký điện tử: Chưa xác minh (Not verified).</p>" }
        let extras = main?.leaves(limit: Int.max).filter { !represented.contains(ObjectIdentifier($0)) && !$0.trimmedValue.isEmpty } ?? []
        if !extras.isEmpty {
            html += "<section class=\"bctc-extra\"><h3>Dữ liệu khác chưa có ánh xạ bố cục</h3><table class=\"tax-table\"><thead><tr><th>Đường dẫn</th><th>Giá trị</th></tr></thead><tbody>"
            for leaf in extras {
                var path = leaf.localName
                var parent = leaf.parent
                while let current = parent, current !== main {
                    path = current.localName + "/" + path
                    parent = current.parent
                }
                html += "<tr><td>\(esc(path))</td><td>\(esc(leaf.trimmedValue))</td></tr>"
            }
            html += "</tbody></table></section>"
        }
        return html + "</section>"
    }

    private func dateWords(_ raw: String) -> String {
        let parts = VietnameseFormat.date(raw).split(separator: "/", omittingEmptySubsequences: false)
        guard parts.count == 3 else { return raw }
        return "\(parts[0]) tháng \(parts[1]) năm \(parts[2])"
    }
}
