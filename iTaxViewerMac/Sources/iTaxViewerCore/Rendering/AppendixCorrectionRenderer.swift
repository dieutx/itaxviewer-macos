import Foundation

/// Independently recreated standard TT80 correction appendices. Factual labels,
/// paths and template/version boundaries are recorded in documents/appendices/
/// correction-tt80.json. Static evidence only; native visual parity is pending.
final class AppendixCorrectionRenderer {
    private let document: TaxDocument
    private var consumed: Set<ObjectIdentifier> = []
    private static let versions: [String: [String: [String]]] = {
        guard let url = Bundle.module.url(forResource: "appendix-correction-versions", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let mappings = try? JSONDecoder().decode([String: [String: [String]]].self, from: data) else { return [:] }
        return mappings
    }()

    init(document: TaxDocument) { self.document = document }

    func render(_ appendix: XMLNode) -> String? {
        guard let code = document.metadata.formCode, let version = document.metadata.formVersion,
              Self.versions[appendix.localName]?[code]?.contains(version) == true else { return nil }
        consumed.removeAll()
        let isExplanation = appendix.localName == "PL01_1_KHBS"
        let form = isExplanation ? "01-1/KHBS" : "01/KHBS"
        let title = isExplanation ? "BẢN GIẢI TRÌNH KHAI BỔ SUNG" : "TỜ KHAI BỔ SUNG"
        var html = "<div class=\"appendix-correction\"><div class=\"doc-title\">\(title)</div>"
        html += "<div class=\"doc-subtitle\">Mẫu số: \(form)</div>"
        html += "<p class=\"c\"><i>Ban hành kèm theo Thông tư số 80/2021/TT-BTC ngày 29 tháng 9 năm 2021 của Bộ trưởng Bộ Tài chính</i></p>"
        if isExplanation { html += "<p class=\"c\"><i>(Kèm theo Tờ khai bổ sung mẫu số 01/KHBS)</i></p>" }
        html += header(appendix, explanation: isExplanation)
        html += isExplanation ? explanation(appendix) : correction(appendix)
        html += remainingValues(appendix)
        return html + "</div>"
    }

    private func header(_ appendix: XMLNode, explanation: Bool) -> String {
        let meta = document.metadata
        var html = paragraph("[01] Mẫu tờ khai:", text(appendix, "Header/tenTKhai"))
        html += paragraph("[02] Mã giao dịch điện tử:", text(appendix, "Header/maGiaoDich"))
        html += paragraph("[03] Kỳ tính thuế:", VietnameseFormat.period(type: meta.periodType, period: meta.period, from: meta.periodFrom, to: meta.periodTo))
        html += paragraph("[04] Bổ sung lần thứ:", text(appendix, "Header/soLan"))
        html += paragraph("[05] Tên người nộp thuế:", meta.taxpayerName ?? "")
        html += paragraph("[06] Mã số thuế:", meta.taxpayerTaxCode ?? "")
        if !explanation {
            html += paragraph("[07] Tên đại lý thuế (nếu có):", meta.agentName ?? "")
            html += paragraph("[08] Mã số thuế:", meta.agentTaxCode ?? "")
            html += paragraph("[09] Hợp đồng đại lý thuế: Số", meta.agentContractNumber ?? "")
            html += paragraph("Ngày:", VietnameseFormat.date(meta.agentContractDate))
        }
        return html
    }

    private func correction(_ appendix: XMLNode) -> String {
        var html = heading("A. Xác định tăng/giảm số thuế phải nộp và tiền chậm nộp, tăng/giảm số thuế được khấu trừ, tăng/giảm số thuế đề nghị hoàn:")
        html += heading("I. Xác định tăng/giảm số thuế phải nộp và tiền chậm nộp:")
        html += paragraph("1. Số thuế phải nộp trên tờ khai điều chỉnh tăng/giảm:", "")
        html += changeTable(appendix.node(atLocalPath: "Muc_A/Muc_I/Muc_1"), amountLabel: "Tăng/giảm số thuế phải nộp (tăng ghi (+), giảm ghi (-))", total: "tongCong_ct10", indicator: "10")
        html += paragraph("2. Số thuế phải nộp trên Phụ lục phân bổ điều chỉnh tăng/giảm:", "")
        html += allocationTable(appendix)
        let late = appendix.node(atLocalPath: "Muc_A/Muc_I/Muc_3")
        html += paragraph("3. Xác định số tiền chậm nộp điều chỉnh tăng/giảm (tăng ghi (+), giảm ghi (-)):", "")
        html += paragraph("a) Số ngày chậm nộp tính đến ngày", VietnameseFormat.date(text(late, "ct3a_1")) + ": " + text(late, "ct3a_2"))
        html += paragraph("b) Số tiền chậm nộp tăng/giảm:", number(late, "ct3b"))
        html += heading("II. Số thuế được khấu trừ điều chỉnh tăng/giảm:")
        html += changeTable(appendix.node(atLocalPath: "Muc_A/Muc_II"), amountLabel: "Tăng/giảm số thuế khấu trừ (tăng ghi (+), giảm ghi (-))", total: "tongCong_ct12", indicator: "12")
        html += heading("III. Số thuế đề nghị hoàn điều chỉnh tăng/giảm:")
        html += changeTable(appendix.node(atLocalPath: "Muc_A/Muc_III"), amountLabel: "Tăng/giảm số thuế đề nghị hoàn (tăng ghi (+), giảm ghi (-))", total: "tongCong_ct13", indicator: "13")
        let recovery = appendix.node(atLocalPath: "Muc_B/Muc_I")
        html += heading("B. Số thuế thu hồi hoàn và tiền chậm nộp (nếu có):")
        html += heading("I. Số thuế thu hồi hoàn:")
        html += paragraph("1. Số tiền thu hồi hoàn:", number(recovery, "ct_1") + " Đồng Việt Nam.")
        html += paragraph("2. Quyết định hoàn thuế: Số", text(recovery, "ct_2_so") + " ngày " + VietnameseFormat.date(text(recovery, "ct_2_ngay")) + " cơ quan thuế ban hành quyết định " + text(recovery, "ct_2_CQT_ten"))
        html += paragraph("3. Lệnh hoàn thuế: Số", text(recovery, "ct_3_so") + " ngày " + VietnameseFormat.date(text(recovery, "ct_3_ngay")))
        html += heading("II. Tiền chậm nộp:")
        let lateRecovery = appendix.node(atLocalPath: "Muc_B/Muc_II")
        html += paragraph("1. Số ngày nhận được tiền hoàn thuế:", text(lateRecovery, "ct_1"))
        html += paragraph("2. Số tiền chậm nộp (= số tiền đã được hoàn phải nộp trả NSNN x số ngày nhận được tiền hoàn thuế x mức chậm nộp):", number(lateRecovery, "ct_2"))
        return html
    }

    private func changeTable(_ section: XMLNode?, amountLabel: String, total: String, indicator: String) -> String {
        var html = tableStart(["STT", "Tên Tiểu mục", amountLabel])
        for (index, row) in (section?.children(named: "ChiTiet") ?? []).enumerated() {
            html += tableRow([String(index + 1), joinedName(row, "ct2_ma", "ct2_ten"), number(row, "ct3")])
        }
        html += tableRow(["", "Tổng cộng: [\(indicator)]", number(section, total)], bold: true)
        return html + "</tbody></table>"
    }

    private func allocationTable(_ appendix: XMLNode) -> String {
        let list = appendix.node(atLocalPath: "Muc_A/Muc_I/Muc_2/DSachPLuc")
        var html = tableStart(["STT", "Tên (đơn vị phụ thuộc, địa điểm kinh doanh/tên mặt hàng/tỉnh nơi không có đơn vị phụ thuộc/địa điểm kinh doanh/đơn vị tiêu thụ/cơ sở khai thác)", "Mã số thuế/mã số địa điểm kinh doanh (nếu có)", "Huyện", "Tỉnh", "Cơ quan thuế quản lý địa bàn nhận phân bổ", "Số tiền thuế phải nộp điều chỉnh tăng/giảm (tăng ghi (+), giảm ghi (-))"])
        for (index, group) in (list?.children(named: "BKePLuc") ?? []).enumerated() {
            html += tableRow([String(index + 1), text(group, "ten_PLuc"), "", "", "", "", ""], bold: true)
            for row in group.firstChild(named: "CTietPLuc")?.children(named: "ChiTiet") ?? [] {
                let taxpayer = text(appendix, "Header/maTKhai") == "914" ? joinedName(row, "ct3_ma", "ct3_ten") : text(row, "ct3_ma")
                html += tableRow(["", joinedName(row, "ct2_ma", "ct2_ten"), taxpayer, text(row, "ct04_ten"), text(row, "ct05_ten"), text(row, "ct06_ten"), number(row, "ct7")])
            }
        }
        html += "<tr><td colspan=\"6\"><b>Tổng cộng: [11]</b></td><td class=\"r\"><b>\(esc(number(list, "tongCong_ct11")))</b></td></tr>"
        return html + "</tbody></table>"
    }

    private func explanation(_ appendix: XMLNode) -> String {
        var html = heading("A. Thông tin khai bổ sung:")
        html += tableStart(["STT", "Tên chỉ tiêu điều chỉnh/ Tên hàng hóa, dịch vụ", "Mã số chỉ tiêu", "Số đã kê khai", "Số điều chỉnh", "Chênh lệch/thay đổi giữa số điều chỉnh với số đã kê khai", "Điều chỉnh tăng/giảm nghĩa vụ thuế", "Lý do"])
        let list = appendix.node(atLocalPath: "Muc_A/DSachHSo")
        for (index, group) in (list?.children(named: "BKeHSo") ?? []).enumerated() {
            html += tableRow([String(index + 1), text(group, "ten_HSo"), "", "", "", "", "", ""], bold: true)
            for row in group.firstChild(named: "CTietHSo")?.children(named: "ChiTiet") ?? [] {
                let indicatorName = text(row, "ct2_ten")
                var name = indicatorName.isEmpty ? text(row, "ct3_ten") : indicatorName
                for field in ["ct3_1_ten", "ct3_2_ten"] {
                    let detail = text(row, field)
                    if !detail.isEmpty { name += " - " + detail }
                }
                var code = text(row, "ct3_ma")
                if !indicatorName.isEmpty { code += " - " + text(row, "ct3_ten") }
                // ct04/ct05 are text in the vendor template (dates/text are legal).
                html += tableRow(["", name, code, text(row, "ct04"), text(row, "ct05"), number(row, "ct06"), number(row, "ct7"), text(row, "ct8")])
            }
        }
        for (field, indicator, label) in [("tongCong_7", "07", "phải nộp"), ("tongCong_8", "08", "khấu trừ"), ("tongCong_9", "09", "đề nghị hoàn")] {
            html += "<tr><td></td><td colspan=\"4\"><b>Tổng cộng (tăng +, giảm -) \(label):</b></td><td>[\(indicator)]</td><td class=\"r\"><b>\(esc(number(list?.firstChild(named: "TongCong"), field)))</b></td><td></td></tr>"
        }
        html += "</tbody></table>"
        html += heading("B. Tài liệu kèm theo (nếu có):")
        html += tableStart(["STT", "Tên chỉ tiêu điều chỉnh/ Tên hàng hóa, dịch vụ"])
        for (index, row) in (appendix.firstChild(named: "Muc_B")?.children(named: "CTietTaiLieu") ?? []).enumerated() {
            html += tableRow([String(index + 1), text(row, "ten_TLieu")])
        }
        return html + "</tbody></table>"
    }

    private func text(_ node: XMLNode?, _ path: String) -> String {
        guard let leaf = node?.node(atLocalPath: path) else { return "" }
        consumed.insert(ObjectIdentifier(leaf))
        return leaf.trimmedValue
    }
    private func number(_ node: XMLNode?, _ path: String) -> String { VietnameseFormat.number(text(node, path)) }
    private func joinedName(_ node: XMLNode, _ code: String, _ name: String) -> String {
        [text(node, code), text(node, name)].filter { !$0.isEmpty }.joined(separator: " - ")
    }
    private func esc(_ value: String) -> String { VietnameseFormat.htmlEscape(value) }
    private func heading(_ label: String) -> String { "<p><b>\(esc(label))</b></p>" }
    private func paragraph(_ label: String, _ value: String) -> String { "<p>\(esc(label)) \(esc(value))</p>" }
    private func tableStart(_ labels: [String]) -> String {
        "<table class=\"data-table\"><thead><tr>" + labels.map { "<th>\(esc($0))</th>" }.joined() + "</tr></thead><tbody>"
    }
    private func tableRow(_ values: [String], bold: Bool = false) -> String {
        "<tr>" + values.map { "<td>" + (bold ? "<b>" : "") + esc($0) + (bold ? "</b>" : "") + "</td>" }.joined() + "</tr>"
    }

    /// Keep extensions and future fields visible instead of silently dropping
    /// them. These rows are explicitly supplementary XML, not official labels.
    private func remainingValues(_ appendix: XMLNode) -> String {
        var rows = ""
        func walk(_ node: XMLNode, path: String) {
            if node.localName == "Signature" { return }
            if node.children.isEmpty {
                if !consumed.contains(ObjectIdentifier(node)), !node.trimmedValue.isEmpty {
                    rows += tableRow([path, node.trimmedValue])
                }
            } else {
                for (index, child) in node.children.enumerated() { walk(child, path: path + "/" + child.localName + "[\(index + 1)]") }
            }
        }
        walk(appendix, path: appendix.localName)
        guard !rows.isEmpty else { return "" }
        return heading("Dữ liệu XML bổ sung ngoài bố cục biểu mẫu") + tableStart(["Đường dẫn dữ liệu", "Giá trị"]) + rows + "</tbody></table>"
    }
}
