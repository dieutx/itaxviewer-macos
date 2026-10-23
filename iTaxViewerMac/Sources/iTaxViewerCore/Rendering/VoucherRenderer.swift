import Foundation

/// Official layout for payment voucher CT-01 (C1-02/NS), reconstructed from
/// `docs/reverse-engineering/documents/paymentVouchers/CT-01.json`.
///
/// The template hard-codes "Chuyển khoản [X]" and ignores `HTHUC_NOP`
/// (verified on the original), so that is reproduced here. Labels come from
/// the spec; no vendor XSLT is used.
final class VoucherRenderer {

    private let document: TaxDocument

    init(document: TaxDocument) {
        self.document = document
    }

    func render() -> String? {
        guard document.root.localName == "CHUNGTU",
              document.metadata.voucherCode == "01",
              let header = document.root.firstDescendant(named: "CHUNGTU_HDR") else {
            return nil
        }
        let currency = text(header, "MA_NGUYENTE")
        let rows = document.root.descendants(named: "ROW_CTIET")

        var s = "<div class=\"notice-header voucher-header\">"
        s += "<div class=\"voucher-form\">Mẫu số: <b>C1-02/NS</b></div>"
        s += "<div class=\"doc-title\">GIẤY NỘP TIỀN VÀO NGÂN SÁCH NHÀ NƯỚC</div>"
        s += "<div class=\"doc-subtitle\">Ban hành kèm theo Thông tư số 84/2016/TT-BTC của Bộ Tài chính</div>"
        s += "<table class=\"voucher-meta\"><tr>"
        s += "<td>Mã hiệu: <b>\(esc(orDash(value("MAHIEU_CTU"))))</b></td>"
        s += "<td>Số: <b>\(esc(orDash(value("SO_GNT") ?? value("SO_CTU"))))</b></td>"
        s += "<td>Số tham chiếu: \(esc(orDash(text(header, "MA_THAMCHIEU"))))</td>"
        s += "</tr><tr>"
        s += "<td colspan=\"2\">Tiền mặt [ ]&nbsp;&nbsp;Chuyển khoản [X]</td>"
        s += "<td>Loại tiền: \(currencyBoxes(currency))</td>"
        s += "</tr></table>"
        s += "</div>"

        s += "<table class=\"voucher-fields\">"
        s += fieldRow("Người nộp thuế", text(header, "TEN_NNOP"), "Mã số thuế", text(header, "MST_NNOP"))
        s += fieldRow("Địa chỉ", text(header, "DIACHI_NNOP"), "Quận/Huyện", text(header, "TEN_HUYEN_NNOP"))
        s += fieldRow("Tỉnh, TP", text(header, "TEN_TINH_NNOP"), "Người nộp thay", text(header, "TEN_NTHAY"))
        s += fieldRow("Mã số thuế (nộp thay)", text(header, "MST_NTHAY"), "Địa chỉ (nộp thay)", text(header, "DIACHI_NTHAY"))
        s += fieldRow("Quận/Huyện (nộp thay)", text(header, "TEN_HUYEN_NTHAY"), "Tỉnh, TP (nộp thay)", text(header, "TEN_TINH_NTHAY"))
        s += fieldRow("Đề nghị NH (KBNN)", text(header, "TEN_NHANG_NOP"), "trích TK số", text(header, "STK_NHANG_NOP"))
        s += fieldRow("Vào tài khoản của KBNN", text(header, "TEN_KBAC"), "Tỉnh, TP (KBNN)", text(header, "TEN_TINH_KBAC"))
        s += fieldRow("Mở tại NHTM ủy nhiệm thu", text(header, "TEN_NHANG_UNT"), "Tại cơ quan quản lý thu", text(header, "TEN_CQTHU"))
        s += "</table>"

        s += "<div class=\"notice-body\"><p class=\"voucher-account-line\">"
        s += "Nộp vào <b>[\(text(header, "STK_THU") == "7111" ? "X" : " ")]</b> cho NSNN&nbsp;&nbsp;"
        s += "<b>[\(["8991", "3121", "8993", "3397"].contains(text(header, "STK_THU")) ? "X" : " ")]</b> TK thu hồi hoàn thuế GTGT&nbsp;&nbsp;"
        s += "<b>[ ]</b> TK tạm thu"
        s += "</p></div>"

        s += "<div class=\"voucher-section-title\">Phần dành cho NNT ghi khi nộp tiền vào NSNN</div>"
        s += voucherTable(rows: rows, currency: currency, header: header)

        s += "<p class=\"voucher-words\"><b>Tổng số tiền ghi bằng chữ:</b> \(esc(amountInWords(text(header, "TONG_TIEN"))))</p>"

        s += "<div class=\"voucher-section-title\">PHẦN KBNN GHI</div>"
        s += "<table class=\"voucher-kbac\"><tr>"
        s += "<td>Mã CQ thu: ................</td><td>Nợ TK: ................</td>"
        s += "<td>Mã ĐBHC: ................</td><td>Có TK: ................</td>"
        s += "</tr><tr><td colspan=\"2\">Mã nguồn NSNN: ......................</td>"
        s += "<td colspan=\"2\">Tỷ giá hạch toán: ................</td></tr></table>"

        s += "<div class=\"date-line voucher-signature\">Ngày \(esc(voucherDate(header)))</div>"
        s += "<table class=\"signature-table\"><tr>"
        s += "<td><b>NGƯỜI NỘP TIỀN</b><br/><i>(Ký, ghi rõ họ tên)</i></td>"
        s += "<td><b>NGƯỜI NHẬN TIỀN</b><br/><i>(Ký, ghi rõ họ tên)</i></td>"
        s += "</tr></table>"
        return s
    }

    // MARK: - Detail table

    private func voucherTable(rows: [XMLNode], currency: String, header: XMLNode) -> String {
        let isForeign = currency == "USD"
        var s = "<table class=\"voucher-table\"><thead><tr>"
        s += "<th style=\"width:5%\">STT</th>"
        s += "<th>Số tờ khai/ Số quyết định / Số thông báo</th>"
        s += "<th>Kỳ thuế/ Ngày quyết định/ Ngày thông báo</th>"
        s += "<th>Nội dung các khoản nộp NSNN</th>"
        if isForeign {
            s += "<th style=\"width:15%\">Số nguyên tệ</th>"
        } else {
            s += "<th style=\"width:15%\">Số tiền VND</th>"
        }
        s += "<th style=\"width:10%\">Mã chương</th>"
        s += "<th style=\"width:10%\">Mã tiểu Mục</th>"
        s += "</tr></thead><tbody>"
        for (index, row) in rows.enumerated() {
            var content = text(row, "NDUNG_NOP")
            let note = text(row, "GHI_CHU")
            if !note.isEmpty {
                content += ";Ghi chú : \(note)"
            } else {
                content += ";"
            }
            s += "<tr><td class=\"c\">\(index + 1)</td>"
            s += "<td>\(esc(text(row, "SO_TK_TB_QD")))</td>"
            s += "<td>\(esc(text(row, "KY_THUE")))</td>"
            s += "<td>\(esc(content))</td>"
            let amount = text(row, "TIEN_PNOP")
            s += "<td class=\"r\">\(esc(isForeign ? decimal2(amount) : VietnameseFormat.number(amount)))</td>"
            s += "<td class=\"c\">\(esc(text(row, "MA_CHUONG")))</td>"
            s += "<td class=\"c\">\(esc(text(row, "MA_NDKT")))</td></tr>"
        }
        s += "</tbody><tfoot><tr><td colspan=\"4\" class=\"r\"><b>Tổng tiền</b></td>"
        let total = text(header, "TONG_TIEN")
        s += "<td class=\"r\"><b>\(esc(isForeign ? decimal2(total) : VietnameseFormat.number(total)))</b></td>"
        s += "<td colspan=\"2\"></td></tr></tfoot></table>"
        return s
    }

    // MARK: - Helpers

    private func value(_ name: String) -> String? {
        if let node = document.root.firstDescendant(named: name) {
            let text = node.trimmedValue
            return text.isEmpty ? nil : text
        }
        return nil
    }

    private func text(_ node: XMLNode?, _ name: String) -> String {
        guard let child = node?.firstChild(named: name) else { return "" }
        return child.trimmedValue
    }

    private func fieldRow(_ l1: String, _ v1: String, _ l2: String, _ v2: String) -> String {
        "<tr><td class=\"vlabel\">\(esc(l1))</td><td>\(esc(v1))</td>"
        + "<td class=\"vlabel\">\(esc(l2))</td><td>\(esc(v2))</td></tr>"
    }

    private func currencyBoxes(_ currency: String) -> String {
        let code = currency.isEmpty ? "VND" : currency
        func box(_ label: String, _ checked: Bool) -> String {
            "\(label) [\(checked ? "X" : " ")]"
        }
        return [box("VND", code == "VND"), box("USD", code == "USD"), box("Khác", false)]
            .joined(separator: "&nbsp;&nbsp;")
    }

    private func orDash(_ value: String?) -> String {
        guard let value, !value.isEmpty else { return "............" }
        return value
    }

    private func decimal2(_ raw: String) -> String {
        guard let number = Double(raw) else { return raw }
        return String(format: "%.2f", number)
    }

    private func voucherDate(_ header: XMLNode) -> String {
        let raw = text(header, "NGAY_LAP")
        return VietnameseFormat.date(raw.isEmpty ? nil : raw)
    }

    // MARK: - Amount in words (Vietnamese)

    func amountInWords(_ raw: String) -> String {
        let digitsOnly = raw.filter { $0.isNumber }
        guard let amount = Int64(digitsOnly), amount > 0 else {
            return "Không đồng"
        }
        let words = Self.vietnameseWords(amount)
        return words.prefix(1).uppercased() + words.dropFirst() + " đồng"
    }

    static func vietnameseWords(_ number: Int64) -> String {
        let digits = ["không", "một", "hai", "ba", "bốn", "năm", "sáu", "bảy", "tám", "chín"]
        let scales = ["", "nghìn", "triệu", "tỷ", "nghìn tỷ", "triệu tỷ", "tỷ tỷ"]

        func group(_ value: Int, full: Bool) -> [String] {
            let hundred = value / 100
            let ten = (value % 100) / 10
            let unit = value % 10
            var parts: [String] = []
            if full || hundred > 0 {
                parts.append("\(digits[hundred]) trăm")
            }
            if ten == 0 {
                if unit > 0 {
                    if full || hundred > 0 { parts.append("lẻ") }
                    parts.append(digits[unit])
                }
            } else if ten == 1 {
                parts.append("mười")
                if unit > 0 { parts.append(unit == 5 ? "lăm" : digits[unit]) }
            } else {
                parts.append("\(digits[ten]) mươi")
                if unit > 0 {
                    parts.append(unit == 1 ? "mốt" : unit == 5 ? "lăm" : digits[unit])
                }
            }
            return parts
        }

        var groups: [Int] = []
        var remaining = number
        while remaining > 0 {
            groups.append(Int(remaining % 1000))
            remaining /= 1000
        }

        var words: [String] = []
        for index in stride(from: groups.count - 1, through: 0, by: -1) {
            let value = groups[index]
            guard value > 0 else { continue }
            let hasHigher = words.isEmpty == false
            words.append(contentsOf: group(value, full: hasHigher || value >= 100))
            if index < scales.count && !scales[index].isEmpty {
                words.append(scales[index])
            }
        }
        return words.joined(separator: " ")
    }

    private func esc(_ value: String) -> String {
        VietnameseFormat.htmlEscape(value)
    }
}
