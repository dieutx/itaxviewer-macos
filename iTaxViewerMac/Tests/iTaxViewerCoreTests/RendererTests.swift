import XCTest
@testable import iTaxViewerCore

final class FormatterTests: XCTestCase {

    func testThousandsGroupingMatchesOriginalJavascript() {
        XCTAssertEqual(VietnameseFormat.number("1000000000"), "1.000.000.000")
        XCTAssertEqual(VietnameseFormat.number("80000000"), "80.000.000")
        XCTAssertEqual(VietnameseFormat.number("0"), "0")
        XCTAssertEqual(VietnameseFormat.number("250"), "250")
        XCTAssertEqual(VietnameseFormat.number(""), "")
        XCTAssertEqual(VietnameseFormat.number(nil), "")
    }

    func testNegativeValuesUseParentheses() {
        XCTAssertEqual(VietnameseFormat.number("-1000"), "(1.000)")
        XCTAssertEqual(VietnameseFormat.number("-1"), "(1)")
        XCTAssertEqual(VietnameseFormat.number("-0"), "0")
    }

    func testFractionalValuesUseComma() {
        XCTAssertEqual(VietnameseFormat.number("1234.56"), "1.234,56")
    }

    func testDateNormalisation() {
        XCTAssertEqual(VietnameseFormat.date("2025-06-30"), "30/06/2025")
        XCTAssertEqual(VietnameseFormat.date("30/06/2025"), "30/06/2025")
        XCTAssertEqual(VietnameseFormat.date(""), "")
    }

    func testPeriodText() {
        XCTAssertEqual(VietnameseFormat.period(type: "M", period: "06/2025", from: nil, to: nil),
                       "Tháng 06 năm 2025")
        XCTAssertEqual(VietnameseFormat.period(type: "Q", period: "2/2025", from: nil, to: nil),
                       "Quý 2 năm 2025")
        XCTAssertEqual(VietnameseFormat.period(type: "Y", period: "2024", from: nil, to: nil),
                       "Năm 2024")

        // Windows reference: 01/GTGT shows "Tháng 06 năm 2025" even though the
        // XML also carries kyKKhaiTuNgay/kyKKhaiDenNgay.
        XCTAssertEqual(VietnameseFormat.period(type: "M", period: "06/2025",
                                               from: "01/06/2025", to: "30/06/2025"),
                       "Tháng 06 năm 2025")
        XCTAssertEqual(VietnameseFormat.period(type: "Q", period: "2/2025",
                                               from: "01/04/2025", to: "30/06/2025"),
                       "Quý 2 năm 2025")
        XCTAssertEqual(VietnameseFormat.period(type: "Y", period: "2024",
                                               from: "01/04/2024", to: "31/03/2025"),
                       "Năm 2024")
        // No recognised kieuKy: fall back to the explicit date range.
        XCTAssertEqual(VietnameseFormat.period(type: nil, period: nil,
                                               from: "01/01/2025", to: "31/12/2025"),
                       "Từ ngày 01/01/2025 đến ngày 31/12/2025")
    }

    func testHTMLEscaping() {
        XCTAssertEqual(VietnameseFormat.htmlEscape("<a & b>"), "&lt;a &amp; b&gt;")
    }
}

final class RendererTests: XCTestCase {

    private func render(_ fixture: String) throws -> (TaxDocument, Classification, RenderedDocument) {
        let doc = try Fixtures.document(fixture)
        let registry = try FormRegistry.bundled()
        let classification = try DocumentClassifier.classify(doc, registry: registry)
        let rendered = HTMLRenderer(registry: registry).render(document: doc, classification: classification)
        return (doc, classification, rendered)
    }

    func testGTGTRendersOfficialIndicatorsAndFormattedValues() throws {
        let (_, _, rendered) = try render("gtgt_842_return")
        let html = rendered.html
        XCTAssertTrue(html.contains("TỜ KHAI THUẾ GIÁ TRỊ GIA TĂNG"))
        XCTAssertTrue(html.contains("[23]"))
        XCTAssertTrue(html.contains("[43]"))
        XCTAssertTrue(html.contains("1.000.000.000"))
        XCTAssertTrue(html.contains("80.000.000"))
        XCTAssertTrue(html.contains("160.000.000"))
        XCTAssertTrue(html.contains("Thuế giá trị gia tăng còn được khấu trừ kỳ trước chuyển sang"))
        XCTAssertTrue(html.contains("@page { size: A4 portrait"))
        XCTAssertEqual(rendered.orientation, .portrait)
    }

    func testLegacyGTGTVersionRendersOfficialLayout() throws {
        let (_, classification, rendered) = try render("gtgt_01_legacy_212")
        XCTAssertTrue(classification.support.isFull)
        let html = rendered.html
        XCTAssertTrue(html.contains("TỜ KHAI THUẾ GIÁ TRỊ GIA TĂNG"))
        XCTAssertTrue(html.contains("[22]"))
        XCTAssertTrue(html.contains("[43]"))
        XCTAssertTrue(html.contains("1.000.000.000"))
        XCTAssertTrue(html.contains("(115.000.000)"))
        XCTAssertTrue(html.contains("@page { size: A4 portrait"))
    }

    func testNotice843UsesOfficialLayout() throws {
        let (_, classification, rendered) = try render("notice_843")
        XCTAssertEqual(classification.kind, .notice)
        let html = rendered.html
        XCTAssertTrue(html.contains("Mẫu số: <b>01-01/TB-TĐT</b>"))
        XCTAssertTrue(html.contains("V/v: Tiếp nhận hồ sơ khai thuế điện tử"))
        XCTAssertTrue(html.contains("CÔNG TY MẪU"))
        XCTAssertTrue(html.contains("14 giờ 14 phút ngày 20 tháng 06 năm 2025"))
        XCTAssertTrue(html.contains("01/GTGT - TỜ KHAI THUẾ GIÁ TRỊ GIA TĂNG"))
        XCTAssertTrue(html.contains("Mã hồ sơ tra cứu trên Cổng dịch vụ công quốc gia"))
        // The notice layout replaces the raw path/value dump.
        XCTAssertFalse(html.contains("class=\"path\""))
    }

    func testNotice843RejectedBranchShowsReasonTable() throws {
        let (_, _, rendered) = try render("notice_843_rejected")
        let html = rendered.html
        XCTAssertTrue(html.contains("Lý do không tiếp nhận"))
        XCTAssertTrue(html.contains("class=\"notice-table\""))
        XCTAssertTrue(html.contains("Đề nghị"))
    }

    func testNotice844AcceptedBranch() throws {
        let (_, _, rendered) = try render("notice_844")
        let html = rendered.html
        XCTAssertTrue(html.contains("Mẫu số: <b>01-2/TB-TĐT</b>"))
        XCTAssertTrue(html.contains("V/v: Chấp nhận việc nộp hồ sơ khai thuế điện tử"))
        XCTAssertTrue(html.contains("CƠ QUAN THUẾ MẪU"))
        XCTAssertTrue(html.contains("ngày 20/06/2025"))
        XCTAssertFalse(html.contains("class=\"path\""))
    }

    func testTBao0101BSTTUsesOfficialNoticeLayout() throws {
        let (_, classification, rendered) = try render("notice_01_tb_bstt")
        XCTAssertEqual(classification.kind, .notice)
        XCTAssertEqual(classification.displayCode, "01/TB-BSTT")
        let html = rendered.html
        XCTAssertTrue(html.contains("Mẫu số: <b>01/TB-BSTT-NNT</b>"))
        XCTAssertTrue(html.contains("THÔNG BÁO (Lần 1)"))
        XCTAssertTrue(html.contains("CÔNG TY TNHH DỮ LIỆU MẪU"))
        XCTAssertTrue(html.contains("CỤC THUẾ THÀNH PHỐ HÀ NỘI"))
        XCTAssertTrue(html.contains("15 tháng 11 năm 2026"))
        XCTAssertFalse(html.contains("class=\"path\""))
    }

    func testVoucherCT01UsesOfficialLayout() throws {
        let (_, classification, rendered) = try render("voucher_ct01")
        XCTAssertEqual(classification.kind, .paymentVoucher)
        let html = rendered.html
        XCTAssertTrue(html.contains("GIẤY NỘP TIỀN VÀO NGÂN SÁCH NHÀ NƯỚC"))
        XCTAssertTrue(html.contains("Mẫu số: <b>C1-02/NS</b>"))
        XCTAssertTrue(html.contains("Chuyển khoản [X]"))
        XCTAssertTrue(html.contains("VND [X]"))
        XCTAssertTrue(html.contains("1.234.580.235"))
        XCTAssertTrue(html.contains("Một tỷ hai trăm ba mươi bốn triệu năm trăm tám mươi nghìn hai trăm ba mươi lăm đồng"))
        XCTAssertTrue(html.contains("PHẦN KBNN GHI"))
        XCTAssertFalse(html.contains("class=\"path\""))
    }

    func testAmountInWordsHandlesZeroAndSmallValues() {
        let doc = try? Fixtures.document("voucher_ct01")
        let renderer = VoucherRenderer(document: doc!)
        XCTAssertEqual(renderer.amountInWords("0"), "Không đồng")
        XCTAssertEqual(renderer.amountInWords("15"), "Mười lăm đồng")
        XCTAssertEqual(renderer.amountInWords("1005"), "Một nghìn không trăm lẻ năm đồng")
    }

    func testTNDNRendersParenthesisedNegativeValue() throws {
        let (_, _, rendered) = try render("tndn_892_03tndn_v2.9.4")
        XCTAssertTrue(rendered.html.contains("(1.000)"))
        XCTAssertTrue(rendered.html.contains("Tổng lợi nhuận kế toán trước thuế thu nhập doanh nghiệp"))
        XCTAssertTrue(rendered.html.contains("[A1]") || rendered.html.contains("A1"))
    }

    func testTNCNQuyetToanValues() throws {
        let (_, _, rendered) = try render("tncn_953_05qtt")
        XCTAssertTrue(rendered.html.contains("1.500.000.000"))
        XCTAssertTrue(rendered.html.contains("95.000.000"))
        XCTAssertTrue(rendered.html.contains("NVuKhauTruThue") == false)
    }

    func testHeaderPeriodMatchesWindowsReference() throws {
        let (_, _, gtgt) = try render("gtgt_842_return")
        XCTAssertTrue(gtgt.html.contains("Tháng 06 năm 2025"))
        XCTAssertFalse(gtgt.html.contains("Từ ngày 01/06/2025 đến ngày 30/06/2025"))

        let (_, _, tndn) = try render("tndn_892_03tndn_v2.9.4")
        XCTAssertTrue(tndn.html.contains("Năm 2024"))
        XCTAssertFalse(tndn.html.contains("Năm 2024 Từ 01/04/2024"))
    }

    func testQTTAuthorisationSectionNumbering() throws {
        let registry = try FormRegistry.bundled()
        let spec = try XCTUnwrap(registry.spec(for: "05/QTT-TNCN"))
        XCTAssertEqual(spec.rows.first { $0.indicator == "35" }?.stt, "1")
        XCTAssertEqual(spec.rows.first { $0.indicator == "36" }?.stt, "2")
    }

    func testParentRowsAreEmphasisedLikeTheWindowsRenderer() throws {
        let (_, _, gtgt) = try render("gtgt_842_return")
        XCTAssertTrue(gtgt.html.contains("<tr class=\"summary\">"))
        XCTAssertTrue(gtgt.html.contains("tr.section td, tr.summary td, tr.check-row td { font-weight: bold; }"))

        let (_, _, kk) = try render("tncn_394_05kk_tt92")
        XCTAssertTrue(kk.html.contains("<tr class=\"summary\">"))
        XCTAssertTrue(kk.html.contains("<tr class=\"summary\"><td class=\"c\">1</td>"))
    }

    func testPrintCSSAllowsPageBreaksInsideTables() throws {
        let (_, _, rendered) = try render("gtgt_842_return")
        XCTAssertTrue(rendered.html.contains("thead { display: table-header-group; }"))
        XCTAssertTrue(rendered.html.contains("tr { page-break-inside: avoid; break-inside: avoid; }"))
        XCTAssertFalse(rendered.html.contains("tbody, thead { page-break-inside: avoid; }"))
    }

    func testGTGTTableHeaderGroupsValueColumns() throws {
        let (_, _, rendered) = try render("gtgt_842_return")
        XCTAssertTrue(rendered.html.contains("<th colspan=\"2\">Giá trị hàng hóa, dịch vụ"))
        XCTAssertTrue(rendered.html.contains("<th colspan=\"2\">Thuế giá trị gia tăng</th>"))
    }

    func testVATReductionAppendixUsesOfficialLayout() throws {
        let (_, _, rendered) = try render("gtgt_842_nq142")
        let html = rendered.html
        XCTAssertTrue(html.contains("GIẢM THUẾ GIÁ TRỊ GIA TĂNG<br/>THEO NGHỊ QUYẾT SỐ 142/2024/QH15"))
        XCTAssertTrue(html.contains("I. Hàng hóa, dịch vụ mua vào trong kỳ"))
        XCTAssertTrue(html.contains("II. Hàng hóa, dịch vụ bán ra trong kỳ"))
        XCTAssertTrue(html.contains("III. Chênh lệch thuế GTGT"))
        XCTAssertTrue(html.contains("Hàng hóa mẫu A"))
        XCTAssertTrue(html.contains("Dịch vụ mẫu C"))
        XCTAssertTrue(html.contains("[05]"))
        XCTAssertTrue(html.contains("[09]"))
        XCTAssertTrue(html.contains("(10.000.000)"))
        XCTAssertFalse(html.contains("PL_NQ142_GTGT/BangKeTenHHDV/tenHHDV"))
        // The recreated layout replaces the generic appendix warning.
        XCTAssertFalse(rendered.warnings.contains { $0.contains("bố cục in chính thức") })
    }

    func testAppendixIsNotTruncatedAtOldLeafLimit() throws {
        let source = try String(contentsOf: try Fixtures.url("gtgt_842_return"), encoding: .utf8)
        var rows = ""
        for index in 1...150 {
            rows += "<BangKeTenHHDV><tenHHDVMuaVao>Hàng hóa \(index)</tenHHDVMuaVao>"
            rows += "<giaTriHHDVMuaVao>1000</giaTriHHDVMuaVao><thueGTGTHHDV>80</thueGTGTHHDV></BangKeTenHHDV>"
        }
        let appendix = """
        <PLuc><PL_NQ142_GTGT><HH_DV_MuaVaoTrongKy>
        \(rows)
        <tongCongGiaTriHHDVMuaVao>150000</tongCongGiaTriHHDVMuaVao>
        <tongCongThueGTGTHHDV>12000</tongCongThueGTGTHHDV>
        </HH_DV_MuaVaoTrongKy></PL_NQ142_GTGT></PLuc>
        """
        let xml = source.replacingOccurrences(of: "  </HSoKhaiThue>", with: appendix + "\n  </HSoKhaiThue>")
        let doc = try TaxDocument.load(data: Data(xml.utf8), sourceName: "appendix.xml")
        let registry = try FormRegistry.bundled()
        let classification = try DocumentClassifier.classify(doc, registry: registry)
        let rendered = HTMLRenderer(registry: registry).render(document: doc, classification: classification)
        XCTAssertTrue(rendered.html.contains("Hàng hóa 150"))
    }

    func testFlatVATReductionAppendixLayout() throws {
        let source = try String(contentsOf: try Fixtures.url("gtgt_842_return"), encoding: .utf8)
        let appendix = """
        <PLuc><PL_NQ43_GTGT>
        <BangKeTenHHDV><tenHHDV>Dịch vụ 43</tenHHDV><giaTriHHDV>2000</giaTriHHDV>
        <thueSuatTheoQuyDinh>10</thueSuatTheoQuyDinh><thueSuatSauGiam>8</thueSuatSauGiam>
        <thueGTGTDuocGiam>40</thueGTGTDuocGiam></BangKeTenHHDV>
        <tongCongGiaTriHHDV>2000</tongCongGiaTriHHDV>
        <tongCongThueGTGTDuocGiam>40</tongCongThueGTGTDuocGiam>
        </PL_NQ43_GTGT></PLuc>
        """
        let xml = source.replacingOccurrences(of: "  </HSoKhaiThue>", with: appendix + "\n  </HSoKhaiThue>")
        let doc = try TaxDocument.load(data: Data(xml.utf8), sourceName: "appendix43.xml")
        let registry = try FormRegistry.bundled()
        let classification = try DocumentClassifier.classify(doc, registry: registry)
        let rendered = HTMLRenderer(registry: registry).render(document: doc, classification: classification)
        XCTAssertTrue(rendered.html.contains("THEO NGHỊ QUYẾT SỐ 43/2022/QH15"))
        XCTAssertTrue(rendered.html.contains("Dịch vụ 43"))
        XCTAssertTrue(rendered.html.contains("[07]"))
    }

    func testGenericVoucherPreservesSourceFields() throws {
        let (_, classification, rendered) = try render("gnt_chungtu")
        if case .generic = classification.support {} else { XCTFail("Expected generic") }
        // CT-01 now uses the captured C1-02/NS layout instead of the raw
        // path/value dump; all values are still present in the rendered form.
        XCTAssertTrue(rendered.html.contains("GIẤY NỘP TIỀN VÀO NGÂN SÁCH NHÀ NƯỚC"))
        XCTAssertTrue(rendered.html.contains("Tổng số tiền ghi bằng chữ"))
        XCTAssertFalse(rendered.html.contains("class=\"path\""))
    }

    func testNoticeShowsIssuer() throws {
        let (_, _, rendered) = try render("tbao_107_bstt")
        XCTAssertTrue(rendered.html.contains("Cục Thuế Thành phố Hồ Chí Minh"))
        XCTAssertTrue(rendered.html.contains("THÔNG BÁO"))
    }

    func testFormSpecificHeaderNumbering() throws {
        let (_, _, gtgt) = try render("gtgt_842_return")
        XCTAssertTrue(gtgt.html.contains("Tên đại lý thuế (nếu có)"))
        XCTAssertTrue(gtgt.html.contains("[11c]"))
        XCTAssertTrue(gtgt.html.contains("Tên đơn vị phụ thuộc"))

        let (_, _, kk) = try render("tncn_394_05kk_tt92")
        XCTAssertTrue(kk.html.contains("Quận/Huyện"))
        XCTAssertTrue(kk.html.contains("[20]"))

        let (_, _, qtt) = try render("tncn_953_05qtt")
        XCTAssertTrue(qtt.html.contains("Tổ chức có quyền quyết toán theo uỷ quyền"))
        XCTAssertTrue(qtt.html.contains("NGHĨA VỤ KHẤU TRỪ THUẾ"))

        let (_, _, tndn) = try render("tndn_892_03tndn_v2.9.4")
        XCTAssertTrue(tndn.html.contains("Ngành nghề có tỷ lệ doanh thu cao nhất"))
        XCTAssertTrue(tndn.html.contains("(1)"))
    }

    func testGeneratedHTMLIsScriptFreeAndHasNoRemoteResources() throws {
        for fixture in ["gtgt_842_return", "tncn_394_05kk_tt92", "tncn_953_05qtt",
                        "tndn_892_03tndn_v2.9.4", "gnt_chungtu", "tbao_107_bstt"] {
            let (_, _, rendered) = try render(fixture)
            let html = rendered.html
            XCTAssertFalse(html.lowercased().contains("<script"), "script in \(fixture)")
            XCTAssertFalse(html.contains("http://"), "remote URL in \(fixture)")
            XCTAssertFalse(html.contains("https://"), "remote URL in \(fixture)")
            XCTAssertFalse(html.contains("<iframe"), "iframe in \(fixture)")
            XCTAssertTrue(html.contains("default-src 'none'"), "CSP missing in \(fixture)")
        }
    }

    func testSignatureIsNotReportedAsVerified() throws {
        let (doc, classification, rendered) = try render("signed_demo")
        XCTAssertEqual(doc.signatures.count, 1)
        XCTAssertEqual(doc.signatures.first?.status, SignatureVerificationStatus.notVerified)
        XCTAssertTrue(rendered.html.contains("Chưa xác minh"))
        XCTAssertFalse(rendered.html.contains("Chữ ký điện tử hợp lệ"))
        _ = classification
    }

    func testSignatureMetadataExtraction() throws {
        let doc = try Fixtures.document("signed_demo")
        let sig = try XCTUnwrap(doc.signatures.first)
        XCTAssertTrue(sig.signatureMethod?.contains("rsa-sha256") == true)
        XCTAssertTrue(sig.digestMethod?.contains("sha256") == true)
        XCTAssertEqual(sig.referenceURI, "#SIGNED_DEMO")
        XCTAssertEqual(sig.timestamp, "2026-01-02T03:04:05")
        XCTAssertEqual(sig.signatureValueBytes, 3)
    }
}

