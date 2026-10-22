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
        XCTAssertEqual(VietnameseFormat.period(type: "M", period: "06/2025",
                                               from: "01/06/2025", to: "30/06/2025"),
                       "Từ ngày 01/06/2025 đến ngày 30/06/2025")
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

    func testGenericVoucherPreservesSourceFields() throws {
        let (_, classification, rendered) = try render("gnt_chungtu")
        if case .generic = classification.support {} else { XCTFail("Expected generic") }
        XCTAssertTrue(rendered.html.contains("SO_GNT"))
        XCTAssertTrue(rendered.html.contains("000000107467693-01309202600000001"))
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

