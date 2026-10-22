import Foundation

public struct RenderedDocument {
    public let html: String
    public let orientation: PageOrientation
    public let warnings: [String]
    public let pageWidthPixels: Int

    public init(html: String, orientation: PageOrientation, warnings: [String], pageWidthPixels: Int) {
        self.html = html
        self.orientation = orientation
        self.warnings = warnings
        self.pageWidthPixels = pageWidthPixels
    }
}

/// Produces a self-contained HTML document from verified tax XML data.
/// The HTML is independently authored (no shipped XSLT is executed or copied)
/// and contains no scripts, no external resources and no network references.
public final class HTMLRenderer {

    private let registry: FormRegistry

    public init(registry: FormRegistry) {
        self.registry = registry
    }

    public func render(document: TaxDocument, classification: Classification) -> RenderedDocument {
        var body: String
        var warnings = classification.warnings + document.warnings

        switch classification.support {
        case .full(let spec):
            body = renderFull(document: document, classification: classification, spec: spec)
        case .generic:
            body = renderGeneric(document: document, classification: classification)
        case .none:
            body = "<p>Không hỗ trợ hiển thị tài liệu này.</p>"
        }

        if let appendix = renderAppendices(document: document) {
            body += appendix
            warnings.append("Tệp có phụ lục. Dữ liệu phụ lục được hiển thị đầy đủ nhưng bố cục in chính thức của từng phụ lục chưa được tái tạo.")
        }

        let html = page(body: body,
                        orientation: classification.orientation,
                        warnings: warnings)
        return RenderedDocument(html: html,
                                orientation: classification.orientation,
                                warnings: warnings,
                                pageWidthPixels: classification.orientation == .landscape ? 1262 : 892)
    }

    // MARK: - Full form rendering

    private func renderFull(document: TaxDocument,
                            classification: Classification,
                            spec: FormSpec) -> String {
        var html = renderHeader(document: document, classification: classification, spec: spec)
        html += "<div class=\"form-body\">"
        if spec.displayCode == "05/QTT-TNCN" {
            html += "<div class=\"form-section-title\">I. NGHĨA VỤ KHẤU TRỪ THUẾ CỦA TỔ CHỨC, CÁ NHÂN TRẢ THU NHẬP</div>"
        }
        html += "<div class=\"currency-note\"><i>Đơn vị tiền: Đồng Việt Nam</i></div>"

        switch spec.displayCode {
        case "01/GTGT":
            html += renderGTGTTable(document: document, spec: spec)
        case "05/KK-TNCN", "05/QTT-TNCN":
            html += renderFiveColumnTable(document: document, spec: spec)
        default:
            html += renderIndicatorValueTable(document: document, spec: spec)
        }

        html += "</div>"
        html += renderFooter(document: document)
        return html
    }

    private func renderGTGTTable(document: TaxDocument, spec: FormSpec) -> String {
        let context = CTieuTKhaiChinh(root: document.root)
        var s = "<table class=\"tax-table gtgt\">"
        s += "<colgroup><col style=\"width:6%\"><col><col style=\"width:9%\"><col style=\"width:22%\"><col style=\"width:9%\"><col style=\"width:22%\"></colgroup>"
        s += "<thead><tr>"
        s += "<th>STT</th><th>Chỉ tiêu</th><th>Mã</th>"
        s += "<th>Giá trị hàng hóa, dịch vụ<br/>(chưa có thuế GTGT)</th>"
        s += "<th>Mã</th><th>Thuế giá trị gia tăng</th>"
        s += "</tr></thead><tbody>"

        for row in spec.rows {
            if row.isCheckbox {
                let checked = checkboxValue(row: row, context: context)
                s += "<tr class=\"check-row\">"
                s += "<td class=\"c\">\(esc(row.stt))</td>"
                s += "<td colspan=\"3\">\(esc(row.label))</td>"
                s += "<td class=\"c code\">\(codeCell(row.codes.first ?? ""))</td>"
                s += "<td class=\"c\">\(checked ? "☒" : "☐")</td>"
                s += "</tr>"
                continue
            }
            if row.isSection {
                s += "<tr class=\"section\"><td class=\"c\">\(esc(shortSTT(row.stt)))</td>"
                s += "<td colspan=\"5\">\(esc(row.label))</td></tr>"
                continue
            }
            let stt = displaySTT(row.stt)
            let values = row.values.map { resolve($0, context: context) }
            let codes = padded(row.codes, to: 2)
            let v1 = values.count > 0 ? format(values[0]) : ""
            let v2 = values.count > 1 ? format(values[1]) : ""
            s += "<tr>"
            s += "<td class=\"c\">\(esc(stt))</td>"
            if values.count <= 1 {
                // Single amount: the original template spans the label over the
                // first value pair and prints the code/value in the right pair.
                s += "<td colspan=\"3\">\(esc(row.label))</td>"
                s += "<td class=\"c code\">\(codeCell(codes[0]))</td>"
                s += "<td class=\"r\">\(esc(v1))</td>"
            } else {
                s += "<td>\(esc(row.label))</td>"
                s += "<td class=\"c code\">\(codeCell(codes[0]))</td>"
                s += "<td class=\"r\">\(esc(v1))</td>"
                s += "<td class=\"c code\">\(codeCell(codes[1]))</td>"
                s += "<td class=\"r\">\(esc(v2))</td>"
            }
            s += "</tr>"
        }
        s += "</tbody></table>"
        return s
    }

    private func renderFiveColumnTable(document: TaxDocument, spec: FormSpec) -> String {
        let context = CTieuTKhaiChinh(root: document.root)
        var insertedQuartersHeading = false
        var s = "<table class=\"tax-table five\">"
        s += "<colgroup><col style=\"width:7%\"><col><col style=\"width:10%\"><col style=\"width:12%\"><col style=\"width:22%\"></colgroup>"
        s += "<thead><tr><th>STT</th><th>Chỉ tiêu</th><th>Mã chỉ tiêu</th><th>Đơn vị tính</th><th>Số người / Số tiền</th></tr></thead><tbody>"

        for row in spec.rows {
            if row.values.first?.root == "qtoan" && !insertedQuartersHeading {
                s += "<tr class=\"section\"><td colspan=\"5\">Phần dành cho tổ chức, cá nhân uỷ quyền quyết toán thay</td></tr>"
                insertedQuartersHeading = true
            }
            if row.isSection {
                s += "<tr class=\"section\"><td class=\"c\">\(esc(shortSTT(row.stt)))</td><td colspan=\"4\">\(esc(row.label))</td></tr>"
                continue
            }
            let stt = displaySTT(row.stt)
            let indicator = row.indicator
            let unit = unitFor(indicator: indicator, displayCode: spec.displayCode)
            let value = row.values.first.map { resolve($0, context: context) } ?? ""
            s += "<tr>"
            s += "<td class=\"c\">\(esc(stt))</td>"
            s += "<td>\(esc(row.label))</td>"
            s += "<td class=\"c code\">\(codeCell(indicator))</td>"
            s += "<td class=\"c\">\(esc(unit))</td>"
            s += "<td class=\"r\">\(esc(format(value)))</td>"
            s += "</tr>"
        }
        s += "</tbody></table>"
        return s
    }

    private func renderIndicatorValueTable(document: TaxDocument, spec: FormSpec) -> String {
        let context = CTieuTKhaiChinh(root: document.root)
        var s = "<table class=\"tax-table iv\">"
        s += "<colgroup><col style=\"width:7%\"><col><col style=\"width:12%\"><col style=\"width:26%\"></colgroup>"
        s += "<thead><tr><th>STT</th><th>Chỉ tiêu</th><th>Mã chỉ tiêu</th><th>Số tiền</th></tr></thead><tbody>"
        if spec.displayCode == "03/TNDN" {
            s += "<tr class=\"colnum\"><td class=\"c\"><i>(1)</i></td><td class=\"c\"><i>(2)</i></td><td class=\"c\"><i>(3)</i></td><td class=\"c\"><i>(4)</i></td></tr>"
        }
        for row in spec.rows {
            if row.isSection {
                let hasSTT = !row.stt.isEmpty && row.stt.count <= 3
                if hasSTT {
                    s += "<tr class=\"section\"><td class=\"c\">\(esc(row.stt))</td><td colspan=\"3\">\(esc(row.label))</td></tr>"
                } else {
                    s += "<tr class=\"section\"><td colspan=\"4\">\(esc(row.label))</td></tr>"
                }
                continue
            }
            let value = row.values.first.map { resolve($0, context: context) } ?? ""
            s += "<tr>"
            s += "<td class=\"c\">\(esc(displaySTT(row.stt)))</td>"
            s += "<td>\(esc(row.label))</td>"
            s += "<td class=\"c code\">\(esc(row.indicator))</td>"
            s += "<td class=\"r\">\(esc(format(value)))</td>"
            s += "</tr>"
        }
        s += "</tbody></table>"
        return s
    }

    // MARK: - Header / footer

    private func renderHeader(document: TaxDocument,
                              classification: Classification,
                              spec: FormSpec?) -> String {
        let meta = document.metadata
        let displayCode = classification.displayCode ?? meta.formCode ?? ""
        let description = meta.formDescription ?? spec?.displayCode ?? ""
        let title = (meta.title ?? "TỜ KHAI THUẾ").uppercased(with: Locale(identifier: "vi_VN"))

        var s = "<div class=\"doc-header\">"
        s += "<table class=\"masthead\"><tr>"
        s += "<td class=\"national\"><b>CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM</b><br/><b>Độc lập – Tự do – Hạnh phúc</b><br/>-------------------------</td>"
        s += "<td class=\"form-id\"><div class=\"form-code\">Mẫu số: <b>\(esc(displayCode))</b></div>"
        s += "<div class=\"form-desc\">(\(esc(shortDescription(description))))</div></td>"
        s += "</tr></table>"

        s += "<div class=\"doc-title\">\(esc(title))</div>"
        if let note = classificationNote(classification: classification) {
            s += "<div class=\"doc-subtitle\">\(esc(note))</div>"
        }
        s += "<div class=\"rule\"></div>"

        let headerRows = headerFields(document: document, displayCode: displayCode)
        s += "<table class=\"taxpayer\">"
        for row in headerRows {
            s += "<tr>"
            if row.code == "02/03" {
                let parts = row.value.components(separatedBy: "Bổ sung")
                if parts.count == 2 {
                    s += "<td colspan=\"2\"><b>[02]</b> \(esc(parts[0]))<b>[03]</b> Bổ sung\(esc(parts[1]))</td>"
                } else {
                    s += "<td colspan=\"2\"><b>[02]</b> \(esc(row.value))</td>"
                }
            } else if row.code.isEmpty {
                s += "<td colspan=\"2\">\(esc(row.label)) \(esc(row.value))</td>"
            } else if let full = row.fullText {
                s += "<td class=\"hcode\"><b>[\(esc(row.code))]</b></td>"
                s += "<td>\(esc(full))</td>"
            } else {
                s += "<td class=\"hcode\"><b>[\(esc(row.code))]</b></td>"
                s += "<td><b>\(esc(row.label))</b> \(esc(row.value))</td>"
            }
            s += "</tr>"
        }
        s += "</table></div>"
        return s
    }

    private struct HeaderRow {
        let code: String
        let label: String
        let value: String
        var fullText: String? = nil
    }

    /// Header layouts recovered from `TKhaiHeader.xsl` and verified against the
    /// live Windows renderer. The numbering is form-specific: on 01/GTGT,
    /// [06]–[08] are the delegated tax agent and [09]–[11c] the dependent units,
    /// while on 05/KK and 05/QTT [06]–[12] are address/contact fields.
    private func headerFields(document: TaxDocument, displayCode: String) -> [HeaderRow] {
        let meta = document.metadata
        let period = VietnameseFormat.period(type: meta.periodType, period: meta.period,
                                             from: meta.periodFrom, to: meta.periodTo)
        let filing = VietnameseFormat.filingTypeLabel(meta.filingType, supplement: meta.supplementNumber)
        var rows: [HeaderRow] = []

        func add(_ code: String, _ label: String, _ value: String?) {
            rows.append(HeaderRow(code: code, label: label, value: value ?? ""))
        }
        func addFull(_ code: String, _ text: String) {
            rows.append(HeaderRow(code: code, label: "", value: "", fullText: text))
        }
        func addContract(_ code: String) {
            let number = meta.agentContractNumber ?? ""
            let date = meta.agentContractDate.map { VietnameseFormat.date($0) } ?? ""
            rows.append(HeaderRow(code: code,
                                  label: "Hợp đồng đại lý thuế:",
                                  value: "Số \(number)     Ngày: \(date)"))
        }

        switch displayCode {
        case "01/GTGT":
            add("01a", "Tên hoạt động sản xuất kinh doanh:", meta.activityName)
            add("01b", "Kỳ tính thuế:", period)
            if !filing.isEmpty { rows.append(HeaderRow(code: "02/03", label: "", value: filing)) }
            add("04", "Tên người nộp thuế:", meta.taxpayerName)
            add("05", "Mã số thuế:", meta.taxpayerTaxCode)
            add("06", "Tên đại lý thuế (nếu có):", meta.agentName)
            add("07", "Mã số thuế:", meta.agentTaxCode)
            addContract("08")
            add("09", "Tên đơn vị phụ thuộc/địa điểm kinh doanh của hoạt động sản xuất kinh doanh khác tỉnh nơi đóng trụ sở chính:", meta.dependentUnitName)
            add("10", "Mã số thuế đơn vị phụ thuộc/Mã số địa điểm kinh doanh:", meta.dependentUnitTaxCode)
            add("11", "Địa chỉ nơi có hoạt động sản xuất kinh doanh khác tỉnh nơi đóng trụ sở chính:", "")
            add("11a", "Xã/Phường/Đặc khu:", meta.dependentWard)
            add("11b", "Quận/Huyện:", meta.dependentDistrict)
            add("11c", "Tỉnh/Thành phố:", meta.dependentProvince)

        case "03/TNDN":
            add("01", "Kỳ tính thuế:", period)
            if !filing.isEmpty { rows.append(HeaderRow(code: "02/03", label: "", value: filing)) }
            add("04", "Ngành nghề có tỷ lệ doanh thu cao nhất:", meta.activityName)
            add("05", "Tỷ lệ (%):", meta.activityRate)
            add("06", "Tên người nộp thuế:", meta.taxpayerName)
            add("07", "Mã số thuế:", meta.taxpayerTaxCode)
            add("08", "Tên đại lý thuế (nếu có):", meta.agentName)
            add("09", "Mã số thuế:", meta.agentTaxCode)
            addContract("10")

        case "05/QTT-TNCN":
            add("01", "Kỳ tính thuế:", period)
            if !filing.isEmpty { rows.append(HeaderRow(code: "02/03", label: "", value: filing)) }
            addFull("04", "Tổ chức có quyền quyết toán theo uỷ quyền của cá nhân được điều chuyển từ tổ chức cũ đến tổ chức mới do tổ chức cũ thực hiện sáp nhập, hợp nhất, chia, tách, chuyển đổi loại hình doanh nghiệp hoặc điều chuyển trong cùng hệ thống [ ]")
            add("05", "Tên người nộp thuế:", meta.taxpayerName)
            add("06", "Mã số thuế:", meta.taxpayerTaxCode)
            add("07", "Địa chỉ:", meta.taxpayerAddress)
            add("", "Xã/Phường/Đặc khu:", meta.taxpayerWard)
            add("08", "Quận/Huyện:", meta.taxpayerDistrict)
            add("09", "Tỉnh/Thành phố:", meta.taxpayerProvince)
            add("10", "Điện thoại:", meta.taxpayerPhone)
            add("11", "Fax:", meta.taxpayerFax)
            add("12", "E-mail:", meta.taxpayerEmail)
            add("13", "Tên đại lý thuế (nếu có):", meta.agentName)
            add("14", "Mã số thuế:", meta.agentTaxCode)
            addContract("15")

        case "05/KK-TNCN":
            add("01", "Kỳ tính thuế:", period)
            if !filing.isEmpty { rows.append(HeaderRow(code: "02/03", label: "", value: filing)) }
            add("04", "Tên người nộp thuế:", meta.taxpayerName)
            add("05", "Mã số thuế:", meta.taxpayerTaxCode)
            add("06", "Địa chỉ:", meta.taxpayerAddress)
            add("07", "Quận/Huyện:", meta.taxpayerDistrict)
            add("08", "Tỉnh/Thành phố:", meta.taxpayerProvince)
            add("09", "Điện thoại:", meta.taxpayerPhone)
            add("10", "Fax:", meta.taxpayerFax)
            add("11", "E-mail:", meta.taxpayerEmail)
            add("12", "Tên đại lý thuế (nếu có):", meta.agentName)
            add("13", "Mã số thuế:", meta.agentTaxCode)
            add("14", "Địa chỉ:", meta.agentAddress)
            add("15", "Quận/Huyện:", meta.agentDistrict)
            add("16", "Tỉnh/Thành phố:", meta.agentProvince)
            add("17", "Điện thoại:", meta.agentPhone)
            add("18", "Fax:", meta.agentFax)
            add("19", "E-mail:", meta.agentEmail)
            addContract("20")

        default:
            add("01", "Kỳ tính thuế:", period)
            if !filing.isEmpty { rows.append(HeaderRow(code: "02/03", label: "", value: filing)) }
            add("04", "Tên người nộp thuế:", meta.taxpayerName)
            add("05", "Mã số thuế:", meta.taxpayerTaxCode)
            add("06", "Địa chỉ:", meta.taxpayerAddress)
        }
        return rows
    }

    private func renderFooter(document: TaxDocument) -> String {
        var s = "<div class=\"doc-footer\">"
        if let filingDate = document.metadata.filingDate, !filingDate.isEmpty {
            s += "<div class=\"date-line\">Ngày \(esc(VietnameseFormat.date(filingDate)))</div>"
        }
        s += "<table class=\"signature-table\"><tr>"
        s += "<td><b>NGƯỜI NỘP THUẾ hoặc<br/>ĐẠI DIỆN HỢP PHÁP</b><br/><i>(Ký, ghi rõ họ tên; chữ ký số nếu có)</i></td>"
        s += "<td><b>CƠ QUAN THUẾ TIẾP NHẬN</b><br/><i>(Ký, đóng dấu nếu có)</i></td>"
        s += "</tr></table>"
        if !document.signatures.isEmpty {
            s += "<div class=\"sig-block\">"
            for sig in document.signatures {
                s += "<div class=\"sig-line\"><b>Ký điện tử bởi:</b> \(esc(sig.signerName))"
                if let time = sig.timestamp ?? sig.signingTime, !time.isEmpty {
                    s += " — \(esc(time))"
                }
                s += "<br/><span class=\"sig-warning\">Trạng thái: \(esc(sig.status.rawValue))</span></div>"
            }
            s += "</div>"
        }
        s += "</div>"
        return s
    }

    // MARK: - Generic / notices

    private func renderGeneric(document: TaxDocument, classification: Classification) -> String {
        let meta = document.metadata
        var s = "<div class=\"doc-header\">"
        s += "<div class=\"doc-title\">\(esc((meta.title ?? classification.kind.rawValue).uppercased(with: Locale(identifier: "vi_VN"))))</div>"
        if let code = classification.displayCode {
            s += "<div class=\"doc-subtitle\">Mẫu số / mã: \(esc(code))</div>"
        }
        s += "<div class=\"rule\"></div>"
        s += "<table class=\"taxpayer\">"
        let rows: [(String, String?)] = [
            ("Tên người nộp thuế", meta.taxpayerName),
            ("Mã số thuế", meta.taxpayerTaxCode),
            ("Địa chỉ", meta.taxpayerAddress),
            ("Kỳ tính thuế", VietnameseFormat.period(type: meta.periodType, period: meta.period, from: meta.periodFrom, to: meta.periodTo)),
            ("Mã hồ sơ", meta.formCode ?? meta.noticeCode ?? meta.voucherCode),
            ("Phiên bản", meta.formVersion ?? meta.noticeVersion),
            ("Số chứng từ", meta.voucherNumber),
            ("Phần mềm tạo lập", [meta.softwareName, meta.softwareVersion].compactMap { $0 }.joined(separator: " ")),
        ]
        for (label, value) in rows {
            guard let value, !value.isEmpty else { continue }
            s += "<tr><td class=\"glabel\">\(esc(label))</td><td>\(esc(value))</td></tr>"
        }
        s += "</table></div>"

        s += "<div class=\"form-body generic\">"
        s += "<table class=\"data-table\"><thead><tr><th>Đường dẫn dữ liệu</th><th>Giá trị</th></tr></thead><tbody>"
        var count = 0
        for leaf in document.root.leaves(limit: 800) {
            if isSignatureNode(leaf) { continue }
            let value = leaf.trimmedValue
            if value.isEmpty { continue }
            let path = pathString(for: leaf)
            s += "<tr><td class=\"path\">\(esc(path))</td><td>\(esc(value))</td></tr>"
            count += 1
        }
        if count == 0 {
            s += "<tr><td colspan=\"2\">Không có trường dữ liệu dạng văn bản.</td></tr>"
        }
        s += "</tbody></table></div>"
        s += renderFooter(document: document)
        return s
    }

    private func renderAppendices(document: TaxDocument) -> String? {
        guard let pluc = document.root.firstDescendant(named: "PLuc"), !pluc.children.isEmpty else {
            return nil
        }
        var s = "<div class=\"appendix\" style=\"page-break-before: always;\">"
        s += "<h2>PHỤ LỤC</h2>"
        for child in pluc.children {
            s += "<h3>\(esc(child.localName))</h3>"
            s += "<table class=\"data-table\"><tbody>"
            for leaf in child.leaves(limit: 400) {
                let value = leaf.trimmedValue
                if value.isEmpty { continue }
                s += "<tr><td class=\"path\">\(esc(pathString(for: leaf, relativeTo: child)) )</td><td>\(esc(value))</td></tr>"
            }
            s += "</tbody></table>"
        }
        s += "</div>"
        return s
    }

    // MARK: - Value resolution

    private struct CTieuTKhaiChinh {
        let root: XMLNode
        var tkchinh: XMLNode? { root.firstDescendant(named: "CTieuTKhaiChinh") }
        var ktru: XMLNode? { tkchinh?.firstChild(named: "NVuKhauTruThue") }
        var qtoan: XMLNode? { tkchinh?.firstChild(named: "NVuQToanThay") }
        var ttkthue: XMLNode? { root.firstDescendant(named: "TTinTKhaiThue") }

        func context(_ name: String?) -> XMLNode? {
            switch name {
            case "tkchinh": return tkchinh
            case "ktru": return ktru
            case "qtoan": return qtoan
            case "ttkthue": return ttkthue
            default: return tkchinh
            }
        }
    }

    private func resolve(_ value: FormSpec.Value, context: CTieuTKhaiChinh) -> String {
        guard let base = context.context(value.root) else { return "" }
        guard let node = value.path.isEmpty ? base : base.node(atLocalPath: value.path) else { return "" }
        return node.trimmedValue
    }

    private func checkboxValue(row: FormSpec.Row, context: CTieuTKhaiChinh) -> Bool {
        guard let value = row.values.first else { return false }
        let raw = resolve(value, context: context).lowercased()
        return raw == "true" || raw == "1" || raw == "x" || raw == "có"
    }

    private func format(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "" }
        let numeric = trimmed.replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: ".")
        if Double(numeric) != nil, trimmed.rangeOfCharacter(from: CharacterSet(charactersIn: "0123456789")) != nil {
            return VietnameseFormat.number(trimmed)
        }
        return trimmed
    }

    private func unitFor(indicator: String, displayCode: String) -> String {
        guard let number = Int(indicator.filter({ $0.isNumber })) else { return "" }
        if displayCode == "05/KK-TNCN" { return number <= 25 ? "Người" : "VNĐ" }
        if displayCode == "05/QTT-TNCN" { return number <= 22 ? "Người" : "VNĐ" }
        return ""
    }

    private func displaySTT(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        // Some rows carry the label in the first cell (sub-items without STT).
        return trimmed.count <= 4 ? trimmed : ""
    }

    private func shortSTT(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count <= 4 ? trimmed : ""
    }

    private func padded(_ values: [String], to count: Int) -> [String] {
        var result = values
        while result.count < count { result.append("") }
        return Array(result.prefix(count))
    }

    private func codeCell(_ code: String) -> String {
        code.isEmpty ? "" : "[\(esc(code))]"
    }

    private func classificationNote(classification: Classification) -> String? {
        if classification.displayCode == "01/GTGT" {
            return "(Áp dụng đối với người nộp thuế tính thuế theo phương pháp khấu trừ có hoạt động sản xuất kinh doanh)"
        }
        if classification.displayCode == "05/KK-TNCN" {
            return "(Áp dụng cho tổ chức, cá nhân trả các khoản thu nhập từ tiền lương, tiền công)"
        }
        if classification.displayCode == "05/QTT-TNCN" {
            return "(Áp dụng đối với tổ chức, cá nhân trả thu nhập chịu thuế từ tiền lương, tiền công)"
        }
        if classification.displayCode == "03/TNDN" {
            return "(Áp dụng đối với phương pháp doanh thu – chi phí)"
        }
        return nil
    }

    private func shortDescription(_ text: String) -> String {
        var s = text
        if s.hasPrefix("(") && s.hasSuffix(")") { s = String(s.dropFirst().dropLast()) }
        return s
    }

    private func isSignatureNode(_ node: XMLNode) -> Bool {
        var current: XMLNode? = node
        while let n = current {
            if n.localName == "Signature" || n.localName == "KeyInfo" { return true }
            current = n.parent
        }
        return false
    }

    private func pathString(for node: XMLNode, relativeTo base: XMLNode? = nil) -> String {
        var parts: [String] = []
        var current: XMLNode? = node
        while let n = current, n !== base {
            parts.append(n.localName)
            current = n.parent
        }
        return parts.reversed().joined(separator: "/")
    }

    private func esc(_ value: String) -> String {
        VietnameseFormat.htmlEscape(value)
    }

    // MARK: - Page shell

    private func page(body: String, orientation: PageOrientation, warnings: [String]) -> String {
        let landscape = orientation == .landscape
        let width = landscape ? 1262 : 892
        let warningHTML = warnings.isEmpty ? "" : """
        <div class="warnings no-print">
          <b>Cảnh báo hiển thị:</b>
          <ul>\(warnings.map { "<li>\(esc($0))</li>" }.joined())</ul>
        </div>
        """
        return """
        <!DOCTYPE html>
        <html lang="vi">
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src 'unsafe-inline'; img-src data:;">
        <title>\(esc("iTaxViewer — Tài liệu thuế"))</title>
        <style>
        :root { color-scheme: light; }
        * { box-sizing: border-box; }
        html, body { margin: 0; padding: 0; background: #565656; }
        body { font-family: "Times New Roman", Times, "Liberation Serif", serif; color: #000; font-size: 12pt; }
        .paper { width: \(width)px; max-width: 100%; margin: 22px auto 40px auto; background: #fff;
                 padding: 34px 30px 30px 30px; box-shadow: 0 2px 18px rgba(0,0,0,.45); }
        .warnings { background: #fff7e0; border: 1px solid #d8b45a; color: #4a3600; padding: 8px 12px;
                    font-family: -apple-system, "Helvetica Neue", sans-serif; font-size: 11px; margin-bottom: 16px; }
        .warnings ul { margin: 4px 0 0 18px; padding: 0; }
        .masthead { width: 100%; border-collapse: collapse; }
        .masthead td { vertical-align: top; border: none; padding: 0; }
        .national { width: 68%; text-align: center; font-size: 11.5pt; line-height: 1.35; }
        .form-id { width: 32%; text-align: center; font-size: 10pt; }
        .form-code { font-size: 11pt; }
        .form-desc { font-size: 8.5pt; font-style: italic; margin-top: 3px; line-height: 1.25; }
        .doc-title { text-align: center; font-size: 15pt; font-weight: bold; margin: 12px 0 2px 0;
                     text-transform: uppercase; letter-spacing: .2px; }
        .doc-subtitle { text-align: center; font-size: 9.5pt; font-style: italic; margin: 0 auto 6px auto; max-width: 78%; line-height: 1.3; }
        .rule { border-top: 1px solid #000; margin: 8px 0 10px 0; }
        .taxpayer { width: 100%; border-collapse: collapse; margin-bottom: 8px; }
        .taxpayer td { border: none; padding: 2px 4px; vertical-align: top; font-size: 11pt; }
        .taxpayer .hcode { width: 52px; white-space: nowrap; }
        .glabel { width: 32%; font-weight: bold; }
        .currency-note { text-align: right; font-size: 10pt; margin: 4px 2px 4px 0; }
        .form-section-title { font-weight: bold; font-size: 11.5pt; margin: 10px 0 2px 0; }
        tr.colnum td { font-size: 9.5pt; color: #333; }
        table.tax-table, table.data-table { width: 100%; border-collapse: collapse; table-layout: fixed; }
        table.tax-table th, table.tax-table td, table.data-table th, table.data-table td {
            border: 1px solid #000; padding: 3px 4px; vertical-align: middle; font-size: 10.5pt; line-height: 1.25;
        }
        table.tax-table th, table.data-table th { text-align: center; font-weight: bold; background: #fff; }
        tr.section td { font-weight: bold; }
        td.c, th.c { text-align: center; }
        td.r { text-align: right; white-space: nowrap; }
        td.code { white-space: nowrap; font-weight: bold; }
        .form-body { margin-top: 6px; }
        .doc-footer { margin-top: 18px; page-break-inside: avoid; }
        .date-line { text-align: right; font-style: italic; font-size: 11pt; margin: 6px 8px 10px 0; }
        .signature-table { width: 100%; border-collapse: collapse; margin-top: 6px; }
        .signature-table td { width: 50%; text-align: center; vertical-align: top; padding: 6px; font-size: 10.5pt; }
        .sig-block { margin-top: 10px; border-top: 1px solid #999; padding-top: 6px; font-size: 9.5pt; }
        .sig-warning { color: #8a4b00; }
        h2 { font-size: 14pt; text-align: center; margin: 18px 0 8px 0; }
        h3 { font-size: 11.5pt; margin: 14px 0 4px 0; }
        .data-table .path { font-family: ui-monospace, "SF Mono", Menlo, monospace; font-size: 9pt; color: #333; }
        .data-table td { font-size: 10pt; }
        @page { size: A4 \(landscape ? "landscape" : "portrait"); margin: 20mm 20mm 10mm 20mm; }
        @media print {
          html, body { background: #fff !important; }
          .paper { width: auto !important; max-width: none !important; margin: 0 !important; padding: 0 !important;
                   box-shadow: none !important; }
          .no-print { display: none !important; }
          tr, td, th, tbody, thead { page-break-inside: avoid; }
          thead { display: table-header-group; }
        }
        </style>
        </head>
        <body>
        <div class="paper">
        \(warningHTML)
        \(body)
        </div>
        </body>
        </html>
        """
    }
}
