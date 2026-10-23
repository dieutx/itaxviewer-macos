import Foundation
import XCTest
@testable import iTaxViewerCore

final class AdditionalNoticeRendererTests: XCTestCase {
    func testSuspensionPreservesBothNestedReasonsAndExtensions() throws {
        let doc = try Fixtures.document("notice_01_tb_nsd")
        let html = try XCTUnwrap(AdditionalNoticeRenderer(document: doc).render())
        XCTAssertTrue(html.contains("Về việc ngừng sử dụng hóa đơn"))
        XCTAssertTrue(html.contains("LÝ DO MẪU THỨ NHẤT"))
        XCTAssertTrue(html.contains("LÝ DO MẪU THỨ HAI &amp; BỔ SUNG"))
        XCTAssertTrue(html.contains("NSD-EXTRA-VALUE"))
        XCTAssertTrue(html.contains("0 giờ 0 phút 0 giây ngày 23 tháng 10 năm 2026"))
        XCTAssertFalse(html.contains("01/TB-BSTT-NNT"))
    }

    func testClarificationHasBothTablesAndAllRecords() throws {
        let doc = try Fixtures.document("notice_01_tb_bstt_nnt")
        let html = try XCTUnwrap(AdditionalNoticeRenderer(document: doc).render())
        XCTAssertEqual(html.components(separatedBy: "<table class=\"notice-table\">").count - 1, 2)
        XCTAssertEqual(html.components(separatedBy: "NỘI DUNG MẪU HAI").count - 1, 2)
        XCTAssertTrue(html.contains("TÀI LIỆU MẪU HAI &amp; BA"))
        XCTAssertTrue(html.contains("Thông tin tài liệu"))
        XCTAssertTrue(html.contains("BSTT-NNT-EXTRA-VALUE"))
        XCTAssertTrue(html.contains("trước ngày 09 tháng 11 năm 2026"))
    }

    func testCorrectionReceiptUsesTBTNhanAndOriginalNoticeDate() throws {
        let doc = try Fixtures.document("notice_01_tb_ssdt")
        let html = try XCTUnwrap(AdditionalNoticeRenderer(document: doc).render())
        XCTAssertTrue(html.contains("01/TB-SSĐT"))
        XCTAssertTrue(html.contains("ngày 21 tháng 10 năm 2026"))
        XCTAssertTrue(html.contains("SSDT-RECEIPT-01"))
        XCTAssertTrue(html.contains("SSDT-EXTRA-VALUE"))
        XCTAssertFalse(html.contains("đã xác minh"))
    }

    func testUnknownVersionRootAndCodeNeverReuseAnotherNoticeLayout() throws {
        let source = try String(contentsOf: Fixtures.url("notice_01_tb_ssdt"), encoding: .utf8)
        for xml in [source.replacingOccurrences(of: "2.1.0", with: "99.0.0"),
                    source.replacingOccurrences(of: "TBTNhan", with: "TBao"),
                    source.replacingOccurrences(of: "01/TB-SSĐT", with: "01/TB-TNĐT")] {
            let doc = try TaxDocument.load(data: Data(xml.utf8), sourceName: "unknown.xml")
            XCTAssertNil(AdditionalNoticeRenderer(document: doc).render())
        }
    }

    func testExtensionValuesAreEscapedAndNotTruncated() throws {
        let source = try String(contentsOf: Fixtures.url("notice_01_tb_nsd"), encoding: .utf8)
        let extensions = (1...900).map { "<Field>EXTRA-\($0)</Field>" }.joined()
        let xml = source.replacingOccurrences(of: "</DLTBao>", with: "<Future>" + extensions + "<Payload>&lt;script&gt;unsafe&lt;/script&gt;</Payload></Future></DLTBao>")
        let doc = try TaxDocument.load(data: Data(xml.utf8), sourceName: "extension.xml")
        let html = try XCTUnwrap(AdditionalNoticeRenderer(document: doc).render())
        XCTAssertTrue(html.contains("EXTRA-900"))
        XCTAssertTrue(html.contains("&lt;script&gt;unsafe&lt;/script&gt;"))
        XCTAssertFalse(html.contains("<script>"))
    }
}
