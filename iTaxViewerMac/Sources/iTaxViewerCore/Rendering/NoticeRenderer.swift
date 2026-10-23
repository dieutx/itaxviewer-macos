import Foundation

/// Official layouts for the tax-authority notices that have been captured and
/// specified under `docs/reverse-engineering/documents/notices/`.
///
/// Every literal string here comes from the specification JSON; every value
/// comes from a path recorded in that JSON. Nothing is copied from the vendor
/// XSLT. Notices without a captured layout keep the structured data view.
final class NoticeRenderer {

    private let document: TaxDocument

    init(document: TaxDocument) {
        self.document = document
    }

    func render() -> String? {
        if document.root.localName == "TBao" {
            // The factory accepts several MSo values here; they have different
            // templates. Only this exact code/version has a captured layout.
            guard value(document.root, "MSo") == "01/TB-BSTT",
                  value(document.root, "PBan") == "2.1.0" else { return nil }
            return renderTBaoNotice()
        }
        guard document.root.localName == "TBaoThueDTu",
              document.root.prefix == nil,
              let content = noticeRoot()?.firstChild(named: "NDungTBao"),
              let status = value(content, "trangThai") else { return nil }
        switch document.metadata.noticeCode {
        case "843" where document.metadata.noticeVersion == "2.5.6"
            && ["Y", "0", "N"].contains(status):
            return render843()
        case "844" where document.metadata.noticeVersion == "2.4.9"
            && ["Y", "N"].contains(status):
            return render844()
        default:
            return nil
        }
    }

    // MARK: - 01/TB-BSTT (TBao)

    private func renderTBaoNotice() -> String {
        let root = document.root
        let detail = root.firstChild(named: "DLTBao")
        let number = value(root.node(atLocalPath: "STBao"), "So")
        let date = value(root.node(atLocalPath: "STBao"), "NTBao")
        let taxpayer = value(detail, "TNNT") ?? ""
        let taxOffice = value(detail, "TCQT") ?? ""

        var s = "<div class=\"notice-header\">"
        s += "<table class=\"notice-masthead\"><tr>"
        s += "<td class=\"notice-agency\"><b>\(esc(value(detail, "TCQTCTren") ?? ""))</b><br/><b>\(esc(taxOffice))</b></td>"
        s += "<td class=\"notice-form\"><div>Mẫu số: <b>01/TB-BSTT-NNT</b></div>"
        s += "<div class=\"notice-number\">Số: \(esc(number))</div>"
        s += "<div class=\"notice-date\">\(esc(vietnameseDateLine(date)))</div></td>"
        s += "</tr></table>"
        let round = value(detail, "LGTrinh")
        s += "<div class=\"doc-title\">THÔNG BÁO" + (round.map { " (Lần \(esc($0)))" } ?? "") + "</div>"
        s += "<div class=\"doc-subtitle\">Về việc giải trình, bổ sung thông tin, tài liệu</div>"
        s += "<div class=\"rule\"></div>"
        s += "</div>"

        s += "<div class=\"notice-body\">"
        s += "<p><b>Kính gửi:</b> \(esc(taxpayer))</p>"
        s += "<p><b>Mã số thuế:</b> \(esc(value(detail, "MST")))</p>"
        s += "<p><b>Địa chỉ nhận thông báo:</b> \(esc(value(detail, "DCNNT")))</p>"
        s += "<p>Căn cứ quy định của pháp luật thuế hiện hành về trách nhiệm của người nộp thuế trong việc cung cấp thông tin theo yêu cầu của cơ quan quản lý thuế;</p>"
        s += "<p>Để làm rõ các nội dung: \(esc(taxpayer)) thuộc diện rủi ro rất cao theo mức độ rủi ro người nộp thuế tại ngày phân tích \(esc(dateText(value(detail, "NPTich")))).</p>"
        s += "<p>\(esc(taxOffice)) đề nghị \(esc(taxpayer)) giải trình và bổ sung thông tin, tài liệu theo Phụ lục đính kèm.</p>"
        if let deadline = value(detail, "THGTBSung") {
            let parts = deadline.prefix(10).split(separator: "-")
            let text = parts.count == 3 ? "\(parts[2]) tháng \(parts[1]) năm \(parts[0])" : dateText(deadline)
            s += "<p>Văn bản giải trình, thông tin, tài liệu bổ sung gửi về cơ quan quản lý thuế \(esc(taxOffice)) trước ngày \(esc(text)).</p>"
        }
        s += "<p>Nếu có vướng mắc, đề nghị người nộp thuế liên hệ với cơ quan quản lý thuế \(esc(taxOffice)) theo số điện thoại: \(esc(value(detail, "DTCQT"))) địa chỉ: \(esc(value(detail, "DCCQT"))).</p>"
        s += "<p>\(esc(taxOffice)) thông báo để \(esc(taxpayer)) được biết và thực hiện./.</p>"
        s += "</div>"

        s += "<div class=\"notice-body\">"
        s += "<p><b>Ghi chú</b></p>"
        s += "<p>NNT vui lòng truy cập cổng dịch vụ công: https://dichvucong.gdt.gov.vn/tthc/ để thực hiện giải trình bổ sung thông tin.</p>"
        s += "<p>Trong trường hợp người nộp thuế cần giải trình bổ sung thông tin trực tiếp. Người nộp thuế vui lòng liên hệ cơ quan Thuế và đến trực tiếp tại cơ quan thuế quản lý để thực hiện giải trình bổ sung thông tin</p>"
        s += "</div>"

        s += "<div class=\"notice-signature\">"
        s += "<p><b>Nơi nhận:</b><br/>- Như trên;<br/>- Lưu VT;</p>"
        s += "<div class=\"date-line\">\(esc(vietnameseDateLine(date)))</div>"
        s += "<p style=\"text-align:center\"><b>THỦ TRƯỞNG CƠ QUAN QUẢN LÝ THUẾ</b><br/><b>BAN HÀNH THÔNG BÁO</b><br/><i>(Ký, ghi rõ họ tên, đóng dấu)</i></p>"
        s += "</div>"
        return s
    }

    // MARK: - 843 (01-01/TB-TĐT)

    private func render843() -> String {
        let tbao = noticeRoot()
        let common = tbao?.firstChild(named: "TTinChung")
        let content = tbao?.firstChild(named: "NDungTBao")
        let status = value(content, "trangThai")
        let recipient = value(common?.firstChild(named: "NNhanTBaoThue"), "tenNNhan")
        let agent = value(common?.firstChild(named: "DaiLyThue"), "tenDLT")

        var s = header(formNumber: "01-01/TB-TĐT",
                       agency: ["BỘ TÀI CHÍNH", "TỔNG CỤC THUẾ"],
                       number: value(common?.firstChild(named: "TTinTBaoThue"), "soTBao"),
                       numberSuffix: "/TB-TĐT",
                       date: value(common?.firstChild(named: "TTinTBaoThue"), "ngayTBao"),
                       title: "THÔNG BÁO",
                       summary: "V/v: Tiếp nhận hồ sơ khai thuế điện tử")

        s += basis()

        if status == "Y" || status == "0" {
            s += "<div class=\"notice-body\">"
            s += "<p>Căn cứ hồ sơ khai thuế/BCTC/BCAC của <b>\(esc(recipient))</b>"
            if let agent, !agent.isEmpty { s += " do \(esc(agent))" }
            s += " gửi tới cơ quan thuế lúc \(esc(dateTimeParts(value(content, "ngayHoSo")))), cụ thể như sau:</p>"
            s += declarationLines(content)
            s += "<p>Hồ sơ khai thuế của người nộp thuế đã được cơ quan thuế tiếp nhận vào lúc \(esc(dateTimeText(value(content, "ngayHoSo")))).</p>"
            s += "<p>Hồ sơ khai thuế sẽ được cơ quan thuế tiếp tục kiểm tra và trả Thông báo chấp nhận hoặc không chấp nhận hồ sơ trong thời gian 01 (một) ngày làm việc kể từ ngày cơ quan thuế tiếp nhận hồ sơ của người nộp thuế ghi trên Thông báo này.</p>"
            s += "</div>"
        } else if status == "N" {
            s += "<div class=\"notice-body\">"
            s += "<p>Căn cứ hồ sơ khai thuế/BCTC/BCAC của <b>\(esc(recipient))</b> gửi tới cơ quan thuế. Cơ quan thuế thông báo về việc không tiếp nhận hồ sơ khai thuế/BCTC/BCAC của người nộp thuế, cụ thể như sau:</p>"
            s += declarationLines(content)
            s += "<p><b>- Lý do không tiếp nhận:</b></p>"
            s += rejectionTable(content)
            s += "<p>Đề nghị \(esc(recipient)) điều chỉnh và gửi lại hồ sơ khai thuế/BCTC/BCAC theo hướng dẫn nêu trên để được ghi nhận nghĩa vụ nộp hồ sơ khai thuế theo quy định.</p>"
            s += "</div>"
        }

        s += "<div class=\"notice-body\">"
        s += "<p>Nếu có vướng mắc, xin vui lòng truy cập theo đường dẫn https://thuedientu.gdt.gov.vn hoặc liên hệ với cơ quan thuế nơi nộp hồ sơ để được hỗ trợ.</p>"
        s += "<p>Cơ quan thuế thông báo để \(esc(recipient)) biết và thực hiện./.</p>"
        if let maDVC = value(content, "maDVC"), !maDVC.isEmpty {
            s += "<p>Mã hồ sơ tra cứu trên Cổng dịch vụ công quốc gia: \(esc(maDVC))</p>"
        }
        s += "</div>"
        return s
    }

    // MARK: - 844 (01-2/TB-TĐT)

    private func render844() -> String {
        let tbao = noticeRoot()
        let common = tbao?.firstChild(named: "TTinChung")
        let content = tbao?.firstChild(named: "NDungTBao")
        let status = value(content, "trangThai")
        let recipient = value(common?.firstChild(named: "NNhanTBaoThue"), "tenNNhan")
        let taxOffice = value(common?.firstChild(named: "CQT"), "tenCQT")
        let summary = status == "N"
            ? "V/v: Không chấp nhận việc nộp hồ sơ khai thuế điện tử"
            : "V/v: Chấp nhận việc nộp hồ sơ khai thuế điện tử"

        var s = header(formNumber: "01-2/TB-TĐT",
                       agency: ["BỘ TÀI CHÍNH", "TỔNG CỤC THUẾ"],
                       number: value(common?.firstChild(named: "TTinTBaoThue"), "soTBao"),
                       numberSuffix: "/TB-TĐT",
                       date: value(common?.firstChild(named: "TTinTBaoThue"), "ngayTBao"),
                       title: "THÔNG BÁO",
                       summary: summary)

        s += basis()

        if status == "Y" {
            s += "<div class=\"notice-body\">"
            s += "<p>Căn cứ hồ sơ khai thuế/BCTC/BCAC của <b>\(esc(recipient))</b> gửi tới cơ quan thuế \(esc(taxOffice)) đã được cổng thông tin điện tử của CỤC THUẾ thông báo tiếp nhận vào lúc \(esc(dateTimeText(value(content, "ngayNopThucTe")))) mã giao dịch điện tử \(esc(value(content, "maGiaoDichDTu"))). Cơ quan thuế thông báo về việc chấp nhận hồ sơ khai thuế/BCTC/BCAC của \(esc(recipient)) gửi tới cơ quan thuế \(esc(taxOffice)), cụ thể như sau:</p>"
            s += declarationLines(content)
            s += "<p>Hồ sơ khai thuế (HSKT) của người nộp thuế được cơ quan thuế chấp nhận vào lúc \(esc(dateTimeText(value(content, "ngayHoanThanh")))). Ngày hoàn thành việc nộp HSKT điện tử của NNT là ngày \(esc(dateText(value(content, "ngayChapNhan")))).</p>"
            s += "<p>Trường hợp hồ sơ cần giải trình, bổ sung thông tin, tài liệu, cơ quan thuế sẽ có thông báo gửi người nộp thuế. Cơ quan thuế sẽ thực hiện trả kết quả giải quyết hồ sơ cho người nộp thuế qua \(esc(value(content, "duongDan"))).</p>"
            s += idTable(content)
            s += "</div>"
        } else if status == "N" {
            s += "<div class=\"notice-body\">"
            s += "<p>Căn cứ hồ sơ khai thuế/BCTC/BCAC của <b>\(esc(recipient))</b> gửi tới cơ quan thuế \(esc(taxOffice)). Cơ quan thuế thông báo về việc không chấp nhận hồ sơ khai thuế/BCTC/BCAC của người nộp thuế, cụ thể như sau:</p>"
            s += declarationLines(content)
            s += "<p><b>- Thông tin có sai sót:</b></p>"
            s += rejectionTable(content, header: ["STT", "Thông tin có sai sót", "Hướng dẫn xử lý", "Ghi chú"], parenthesized: true)
            s += "<p>Đề nghị \(esc(recipient)) điều chỉnh và gửi lại hồ sơ khai thuế/BCTC/BCAC theo hướng dẫn nêu trên để được ghi nhận nghĩa vụ nộp hồ sơ thuế/giải quyết hồ sơ thuế theo quy định (trừ hồ sơ đăng ký thuế).</p>"
            s += "</div>"
        }

        s += "<div class=\"notice-body\">"
        s += "<p>Trường hợp cần biết thêm thông tin chi tiết, NNT vui lòng liên hệ với Cơ quan thuế quản lý trực tiếp để được hỗ trợ.</p>"
        s += "<p>Cơ quan thuế thông báo để NNT biết và thực hiện./.</p>"
        s += "</div>"
        return s
    }

    // MARK: - Building blocks

    private func noticeRoot() -> XMLNode? {
        document.root.localName == "TBaoThue" ? document.root : document.root.firstChild(named: "TBaoThue")
    }

    private func header(formNumber: String,
                        agency: [String],
                        number: String?,
                        numberSuffix: String,
                        date: String?,
                        title: String,
                        summary: String) -> String {
        var s = "<div class=\"notice-header\">"
        s += "<table class=\"notice-masthead\"><tr>"
        s += "<td class=\"notice-agency\">" + agency.map { "<b>\(esc($0))</b>" }.joined(separator: "<br/>") + "</td>"
        s += "<td class=\"notice-form\"><div>Mẫu số: <b>\(esc(formNumber))</b></div>"
        s += "<div class=\"notice-number\">Số: \(esc((number ?? "").isEmpty ? "........" : "\(number!)\(numberSuffix)"))</div>"
        s += "<div class=\"notice-date\">\(esc(vietnameseDateLine(date)))</div></td>"
        s += "</tr></table>"
        s += "<div class=\"doc-title\">\(esc(title))</div>"
        s += "<div class=\"doc-subtitle\">\(esc(summary))</div>"
        s += "<div class=\"rule\"></div>"
        s += "</div>"
        return s
    }

    private func basis() -> String {
        "<div class=\"notice-body\">"
        + "<p>Căn cứ quy định tại Luật Quản lý thuế ngày 13/6/2019;</p>"
        + "<p>Căn cứ quy định tại Thông tư số 19/2021/TT-BTC ngày 18/3/2021 của Bộ trưởng Bộ Tài chính hướng dẫn giao dịch điện tử trong lĩnh vực thuế.</p>"
        + "</div>"
    }

    private func declarationLines(_ content: XMLNode?) -> String {
        let details = content?.firstChild(named: "HoSoThue")?.children(named: "CTietHoSoThue") ?? []
        guard !details.isEmpty else { return "" }
        var s = "<div class=\"notice-fields\">"
        for detail in details {
        s += line("- Tên tờ khai/Phụ lục:", value(detail, "tokhai-phuluc"))
        s += line("- Loại tờ khai:", value(detail, "loaiToKhai"))
        s += line("- Kỳ tính thuế:", value(detail, "kyTinhThue"))
        s += line("- Lần nộp hoặc lần bổ sung:", value(detail, "lanNop"))
        }
        if let maGD = value(content, "maGiaoDichDTu"), !maGD.isEmpty {
            s += line("- Mã giao dịch điện tử:", maGD)
        }
        s += "</div>"
        return s
    }

    private func line(_ label: String, _ value: String?) -> String {
        guard let value, !value.isEmpty else { return "" }
        return "<p>\(esc(label)) \(esc(value))</p>"
    }

    private func rejectionTable(_ content: XMLNode?,
                                header: [String] = ["STT", "Mô tả lỗi", "Hướng dẫn xử lý", "Ghi chú"],
                                parenthesized: Bool = false) -> String {
        let rows = content?.node(atLocalPath: "LyDo")?.children(named: "CTietLyDo") ?? []
        guard !rows.isEmpty else { return "" }
        var s = "<table class=\"notice-table\"><thead><tr>"
        s += header.map { "<th>\(esc($0))</th>" }.joined()
        s += "</tr></thead><tbody>"
        for (index, row) in rows.enumerated() {
            let group = value(row, "tenNhomLoi") ?? ""
            let error = value(row, "tenLoi") ?? ""
            let description = parenthesized && !error.isEmpty
                ? "\(group) (\(error))"
                : [group, error].filter { !$0.isEmpty }.joined(separator: " - ")
            s += "<tr><td class=\"c\">\(index + 1)</td>"
            s += "<td>\(esc(description))</td>"
            s += "<td>\(esc(value(row, "huongDanXuLy") ?? ""))</td>"
            s += "<td>\(esc(value(row, "ghiChu") ?? ""))</td></tr>"
        }
        s += "</tbody></table>"
        return s
    }

    private func idTable(_ content: XMLNode?) -> String {
        let rows = content?.node(atLocalPath: "IDKhoanNop")?.children(named: "CTietIDKhoanNop") ?? []
        guard rows.contains(where: { !$0.trimmedValue.isEmpty }) else { return "" }
        let hasIdentifier = rows.contains { !(value($0, "maDinhDanh") ?? "").isEmpty }
        // The original hides the whole table when every identifier is blank.
        // Preserve other populated fields as explicitly supplementary XML data.
        var s = hasIdentifier
            ? "<p><b>- Thông tin mã định danh khoản phải nộp:</b></p>"
            : "<p><b>Dữ liệu bổ sung từ XML: khoản nộp chưa có mã định danh</b></p>"
        s += "<table class=\"notice-table\"><thead><tr>"
        s += "<th>STT</th><th>Mã định danh khoản phải nộp (ID)</th><th>Số tiền thuế phải nộp</th><th>Loại tiền</th><th>Ghi chú</th>"
        s += "</tr></thead><tbody>"
        for (index, row) in rows.enumerated() {
            s += "<tr><td class=\"c\">\(index + 1)</td>"
            s += "<td>\(esc(value(row, "maDinhDanh") ?? ""))</td>"
            s += "<td class=\"r\">\(esc(VietnameseFormat.number(value(row, "soTienPNop"))))</td>"
            s += "<td class=\"c\">\(esc(value(row, "tenLoaiTien") ?? ""))</td>"
            let supplementary = content?.firstChild(named: "HoSoThue")?
                .children(named: "CTietHoSoThue").contains { value($0, "loaiToKhai") == "Bổ sung" } ?? false
            let amount = Decimal(string: value(row, "soTienPNop") ?? "", locale: Locale(identifier: "en_US_POSIX"))
            var note = ""
            if supplementary, let amount {
                if amount > 0 { note = "Số thuế phải nộp tăng thêm do khai bổ sung" }
                if amount < 0 { note = "Số thuế phải nộp được điều chỉnh giảm do khai bổ sung" }
            }
            s += "<td>\(esc(note))</td></tr>"
        }
        s += "</tbody></table>"
        return s
    }

    // MARK: - Values and dates

    private func value(_ node: XMLNode?, _ name: String) -> String? {
        guard let child = node?.firstChild(named: name) else { return nil }
        let text = child.trimmedValue
        return text.isEmpty ? nil : text
    }

    private func vietnameseDateLine(_ raw: String?) -> String {
        guard let raw, !raw.isEmpty else { return "Hà Nội, ngày ..... tháng ..... năm ......" }
        let parts = raw.prefix(10).split(separator: "-")
        guard parts.count == 3 else { return "Hà Nội, ngày \(VietnameseFormat.date(raw))" }
        return "Hà Nội, ngày \(parts[2]) tháng \(parts[1]) năm \(parts[0])"
    }

    private func dateText(_ raw: String?) -> String {
        guard let raw, !raw.isEmpty else { return "" }
        return VietnameseFormat.date(String(raw.prefix(10)))
    }

    /// "14 giờ 14 phút ngày 20 tháng 06 năm 2025" as printed by 843.
    private func dateTimeParts(_ raw: String?) -> String {
        guard let raw, !raw.isEmpty else { return "" }
        let date = String(raw.prefix(10)).split(separator: "-")
        let time = raw.split(separator: "T").dropFirst().first?.prefix(8).split(separator: ":") ?? []
        guard date.count == 3, time.count >= 2 else { return dateText(raw) }
        return "\(time[0]) giờ \(time[1]) phút ngày \(date[2]) tháng \(date[1]) năm \(date[0])"
    }

    /// "14:14:42 ngày 20/06/2025" used for reception/completion timestamps.
    private func dateTimeText(_ raw: String?) -> String {
        guard let raw, !raw.isEmpty else { return "" }
        let time = raw.split(separator: "T").dropFirst().first?.prefix(8)
        let day = dateText(raw)
        if let time { return "\(time) ngày \(day)" }
        return day
    }

    private func esc(_ value: String) -> String {
        VietnameseFormat.htmlEscape(value)
    }

    private func esc(_ value: String?) -> String {
        value.map(VietnameseFormat.htmlEscape) ?? ""
    }
}
