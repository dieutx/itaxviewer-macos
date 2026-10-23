import Foundation

/// Independent layouts from the factual specs in documents/notices/additional-2.1.0.json.
/// Vendor templates are not bundled. Windows GUI/print parity remains pending.
final class AdditionalNoticeRenderer {
    private let document: TaxDocument
    private var consumed: Set<ObjectIdentifier> = []
    init(document: TaxDocument) { self.document = document }

    func render() -> String? {
        let root = document.root
        guard root.prefix == nil, value(root, "PBan") == "2.1.0",
              let detail = root.firstChild(named: "DLTBao") else { return nil }
        let code = value(root, "MSo")
        let body: String
        switch (root.localName, code) {
        case ("TBao", "01/TB-NSD"): body = suspension(detail)
        case ("TBao", "01/TB-BSTT-NNT"): body = clarification(detail)
        case ("TBTNhan", "01/TB-SSĐT"): body = correctionReceipt(detail)
        default: return nil
        }
        // Build the body first so its fields and the masthead can share the
        // consumed-node ledger; append future fields as labelled source data.
        let html = header(code: code, detail: detail) + body
        return html + supplemental(root)
    }

    private func header(code: String, detail: XMLNode) -> String {
        let root = document.root
        let date = dateWords(value(root, "STBao/NTBao"))
        let agency = code == "01/TB-BSTT-NNT"
            ? "<b>\(esc(value(detail, "TCQTCTren")))</b><br/><b>\(esc(value(detail, "TCQT")))</b>"
            : "BỘ TÀI CHÍNH<br/><b>CỤC THUẾ</b>"
        let subject: String
        switch code {
        case "01/TB-NSD": subject = "Về việc ngừng sử dụng hóa đơn"
        case "01/TB-BSTT-NNT": subject = "Về việc giải trình, bổ sung thông tin, tài liệu"
        default: subject = "Về việc tiếp nhận và kết quả xử lý về việc hóa đơn điện tử/chứng từ điện tử đã lập sai"
        }
        var html = "<div class=\"notice-header\"><div class=\"notice-form\">Mẫu số: <b>\(esc(code))</b></div>"
        if code != "01/TB-SSĐT" {
            html += "<p class=\"r\"><i>(Ban hành kèm theo Nghị định 70/2025/NĐ-CP ngày 20 tháng 3 năm 2025 của Bộ trưởng Bộ Tài chính)</i></p>"
        }
        html += "<table class=\"notice-masthead\"><tr><td class=\"notice-agency\">\(agency)<p>Số: \(esc(value(root, "STBao/So")))</p></td>"
        html += "<td class=\"c\"><b>CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM<br/>Độc lập - Tự do - Hạnh phúc</b><p><i>Hà Nội, \(esc(date))</i></p></td></tr></table>"
        html += "<div class=\"doc-title\">THÔNG BÁO</div><div class=\"doc-subtitle\">\(esc(subject))</div></div>"
        if code != "01/TB-NSD" {
            html += p("Kính gửi: " + value(detail, "TNNT")) + p("Mã số thuế: " + value(detail, "MST"))
        }
        return html
    }

    private func suspension(_ detail: XMLNode) -> String {
        let taxpayer = value(detail, "TNNT")
        let taxCode = value(detail, "MST")
        let date = dateWords(value(document.root, "STBao/NTBao"))
        let number = value(document.root, "STBao/So")
        var html = p("Căn cứ Luật Quản lý thuế ngày 13/6/2019;")
        html += p("Căn cứ Điểm c, Khoản 12, Điều 1 Nghị định số 70/2025/NĐ-CP ngày 20/3/2025 của Chính phủ sửa đổi, bổ sung một số điều của Nghị định số 123/2020/NĐ-CP quy định về hóa đơn, chứng từ;")
        html += p("Căn cứ tờ khai 01/ĐKTĐ-HĐĐT của \(taxpayer) có MST \(taxCode) lập \(date) có mã hồ sơ \(number) thuộc trường hợp tại Điểm c Khoản 12 Điều 1 Nghị định số 70/2025/NĐ-CP ngày 20/3/2025, Cơ quan Thuế thông báo:")
        html += p("Cục thuế thông báo về việc tạm ngừng sử dụng hóa đơn điện tử với " + taxpayer)
        html += p("Mã số thuế: " + taxCode) + p("Địa chỉ trụ sở kinh doanh: " + value(detail, "DChi"))
        html += p("Lý do thông báo ngừng sử dụng hóa đơn điện tử/hóa đơn điện tử khởi tạo từ máy tính tiền:")
        html += "<table class=\"notice-table\"><tbody>"
        for (index, row) in (detail.firstChild(named: "DSLDo")?.children(named: "LDo") ?? []).enumerated() {
            html += "<tr><td class=\"c\">\(index + 1)</td><td>\(esc(value(row, "LDo")))</td></tr>"
        }
        html += "</tbody></table>"
        html += p("Thông báo ngừng sử dụng hóa đơn điện tử/hóa đơn điện tử khởi tạo từ máy tính tiền có hiệu lực kể từ 0 giờ 0 phút 0 giây \(date) đối với tổ chức cung cấp dịch vụ \(taxpayer) có MST \(taxCode).")
        html += p("Người nộp thuế sử dụng hóa đơn điện tử/hóa đơn điện tử khởi tạo từ máy tính tiền kể từ thời điểm thông báo ngừng sử dụng hóa đơn có hiệu lực thi hành thì được coi là sử dụng hóa đơn không hợp pháp theo quy định tại Điều 4 Nghị định số 125/2020/NĐ-CP ngày 19/10/2020 của Chính phủ quy định xử phạt vi phạm hành chính về thuế, hóa đơn hoặc các văn bản sửa đổi, bổ sung (nếu có).")
        return html + signature()
    }

    private func clarification(_ detail: XMLNode) -> String {
        let agency = value(detail, "TCQT")
        let taxpayer = value(detail, "TNNT")
        var html = p("Căn cứ quy định của pháp luật thuế hiện hành về trách nhiệm của người nộp thuế trong việc cung cấp thông tin theo yêu cầu của cơ quan quản lý thuế;")
        html += p("Để làm rõ các nội dung:") + clarificationTable(detail, includeDocuments: false)
        html += p("Về việc giải trình, bổ sung thông tin, tài liệu trong hồ sơ: " + value(detail, "MHSo"))
        html += p("\(agency) đề nghị \(taxpayer) giải trình và bổ sung thông tin, tài liệu sau đây:")
        html += clarificationTable(detail, includeDocuments: true)
        html += p("Văn bản giải trình, thông tin, tài liệu bổ sung gửi về cơ quan quản lý thuế \(agency) trước \(dateWords(value(detail, "THGTBSung"))).")
        html += p("Nếu có vướng mắc, đề nghị người nộp thuế liên hệ với cơ quan quản lý thuế \(agency) theo số điện thoại: \(value(detail, "DTCQT")) địa chỉ: \(value(detail, "DCCQT")).")
        html += p("\(agency) thông báo để \(taxpayer) được biết và thực hiện./.")
        html += "<p><b>Nơi nhận:</b><br/>- Như trên;<br/>- Lưu VT;</p>"
        return html + signature()
    }

    private func clarificationTable(_ detail: XMLNode, includeDocuments: Bool) -> String {
        var labels = ["STT", "Nội dung", "Hồ sơ thuế", "Loại kỳ tính thuế", "Kỳ tính thuế"]
        var fields = ["NDung", "HSThue", "LKTThue", "KTThue"]
        if includeDocuments { labels.append("Thông tin tài liệu"); fields.append("TTTLieu") }
        var html = "<table class=\"notice-table\"><thead><tr>" + labels.map { "<th>\(esc($0))</th>" }.joined() + "</tr></thead><tbody>"
        for (index, row) in (detail.firstChild(named: "DSNDGTBSung")?.children(named: "NDGTBSung") ?? []).enumerated() {
            html += "<tr><td class=\"c\">\(index + 1)</td>" + fields.map { "<td>\(esc(value(row, $0)))</td>" }.joined() + "</tr>"
        }
        return html + "</tbody></table>"
    }

    private func correctionReceipt(_ detail: XMLNode) -> String {
        let date = dateWords(value(detail, "NTBNNT"))
        var html = p("Sau khi xem xét Thông báo hóa đơn điện tử/chứng từ điện tử đã lập sai \(date) của:")
        html += p("Người nộp thuế: " + value(detail, "TNNT")) + p("Mã số thuế: " + value(detail, "MST"))
        html += p("Cơ quan thuế thông báo tiếp nhận hóa đơn điện tử/chứng từ điện tử đã lập sai.")
        html += p("Cơ quan Thuế đã tiếp nhận Thông báo hóa đơn điện tử/chứng từ điện tử đã lập sai \(date) của quý công ty.")
        html += p("Cơ quan thuế thông báo để người nộp thuế biết, thực hiện.")
        return html + p("Mã hồ sơ: " + value(detail, "MHSo"))
    }

    private func value(_ node: XMLNode, _ path: String) -> String {
        guard let field = node.node(atLocalPath: path) else { return "" }
        consumed.insert(ObjectIdentifier(field))
        return field.trimmedValue
    }
    private func esc(_ raw: String) -> String { VietnameseFormat.htmlEscape(raw) }
    private func p(_ raw: String) -> String { "<p>\(esc(raw))</p>" }
    private func signature() -> String {
        "<p class=\"r\"><b>CƠ QUAN THUẾ<br/>THỦ TRƯỞNG CƠ QUAN THUẾ</b><br/><i>(Chữ ký số)</i></p>"
    }
    private func dateWords(_ raw: String) -> String {
        let parts = raw.prefix(10).split(separator: "-")
        guard parts.count == 3 else { return raw }
        return "ngày \(parts[2]) tháng \(parts[1]) năm \(parts[0])"
    }
    private func supplemental(_ root: XMLNode) -> String {
        var rows = ""
        func walk(_ node: XMLNode, path: String) {
            guard node.localName != "Signature" else { return }
            if node.children.isEmpty {
                if !consumed.contains(ObjectIdentifier(node)), !node.trimmedValue.isEmpty {
                    rows += "<tr><td>\(esc(path))</td><td>\(esc(node.trimmedValue))</td></tr>"
                }
            } else {
                var counts: [String: Int] = [:]
                for child in node.children {
                    counts[child.localName, default: 0] += 1
                    walk(child, path: path + "/" + child.localName + "[\(counts[child.localName]!)]")
                }
            }
        }
        walk(root, path: root.localName)
        guard !rows.isEmpty else { return "" }
        return "<section class=\"notice-unmapped\"><h3>Dữ liệu XML bổ sung ngoài bố cục đã đối chiếu</h3><table class=\"data-table\"><thead><tr><th>Đường dẫn dữ liệu</th><th>Giá trị</th></tr></thead><tbody>" + rows + "</tbody></table></section>"
    }
}
