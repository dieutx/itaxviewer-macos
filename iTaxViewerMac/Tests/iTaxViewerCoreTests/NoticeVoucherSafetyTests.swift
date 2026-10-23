import Foundation
import XCTest
@testable import iTaxViewerCore

final class NoticeVoucherSafetyTests: XCTestCase {
    private func document(_ xml: String) throws -> TaxDocument {
        try TaxDocument.load(data: Data(xml.utf8), sourceName: "synthetic.xml")
    }

    func testTBaoRequiresCapturedCodeAndVersion() throws {
        for (code, version) in [("01/TB-NSD", "2.1.0"), ("01/TB-BSTT-NNT", "2.1.0"),
                                ("01/TB-BSTT", "99.0.0"), ("04/SS-HĐĐT", "2.1.0")] {
            let doc = try document("<TBao><MSo>\(code)</MSo><PBan>\(version)</PBan><DLTBao><TNNT>TEST</TNNT></DLTBao></TBao>")
            XCTAssertNil(NoticeRenderer(document: doc).render(), "Unexpected layout for \(code)/\(version)")
        }
        let doc = try Fixtures.document("notice_01_tb_bstt")
        let html = try XCTUnwrap(NoticeRenderer(document: doc).render())
        XCTAssertTrue(html.contains("Về việc giải trình, bổ sung thông tin, tài liệu"))
        XCTAssertTrue(html.contains("<b>CỤC THUẾ THÀNH PHỐ HÀ NỘI</b>"))
    }

    func testNoticeUnknownVersionAndStatusUseStructuredFallback() throws {
        let source = try String(contentsOf: Fixtures.url("notice_843"), encoding: .utf8)
        let version = source.replacingOccurrences(of: "<pbanTBao>2.5.6</pbanTBao>", with: "<pbanTBao>3.0.1</pbanTBao>")
        XCTAssertNotEqual(version, source)
        XCTAssertNil(NoticeRenderer(document: try document(version)).render())
        let status = source.replacingOccurrences(of: "<trangThai>Y</trangThai>", with: "<trangThai>UNKNOWN</trangThai>")
        XCTAssertNotEqual(status, source)
        XCTAssertNil(NoticeRenderer(document: try document(status)).render())
    }

    func testNoticeKeepsRepeatedDeclarationDetails() throws {
        let source = try String(contentsOf: Fixtures.url("notice_843"), encoding: .utf8)
        let xml = source.replacingOccurrences(of: "</HoSoThue>", with: "<CTietHoSoThue><tokhai-phuluc>SECOND DECLARATION</tokhai-phuluc><kyTinhThue>2025</kyTinhThue></CTietHoSoThue></HoSoThue>")
        let html = try XCTUnwrap(NoticeRenderer(document: try document(xml)).render())
        XCTAssertTrue(html.contains("SECOND DECLARATION"))
    }

    func testVoucherKeepsEachHeaderAndTotalWithItsOwnRows() throws {
        func record(_ payer: String, _ amount: String, _ detail: String) -> String {
            """
            <NDUNG_CTU><CHUNGTU_HDR><PBAN_TLIEU_XML>4.0.1</PBAN_TLIEU_XML>
            <MA_CTU>01</MA_CTU><TEN_NNOP>\(payer)</TEN_NNOP><TONG_TIEN>\(amount)</TONG_TIEN>
            <MA_NGUYENTE>VND</MA_NGUYENTE></CHUNGTU_HDR><CHUNGTU_CTIET>
            <ROW_CTIET><NDUNG_NOP>\(detail)</NDUNG_NOP><TIEN_PNOP>\(amount)</TIEN_PNOP></ROW_CTIET>
            </CHUNGTU_CTIET></NDUNG_CTU>
            """
        }
        let xml = "<CHUNGTU><NDUNG_CTU_NH><SO_CTU>ENVELOPE-NUMBER</SO_CTU>" + record("FIRST PAYER", "1000", "FIRST DETAIL") + record("SECOND PAYER", "2000", "SECOND DETAIL") + "</NDUNG_CTU_NH></CHUNGTU>"
        let html = try XCTUnwrap(VoucherRenderer(document: try document(xml)).render())
        let bodies = html.components(separatedBy: "<div style=\"page-break-before: always\"></div>")
        XCTAssertEqual(bodies.count, 2)
        XCTAssertTrue(bodies[0].contains("FIRST PAYER"))
        XCTAssertTrue(bodies[0].contains("FIRST DETAIL"))
        XCTAssertFalse(bodies[0].contains("SECOND DETAIL"))
        XCTAssertTrue(bodies[1].contains("SECOND PAYER"))
        XCTAssertTrue(bodies[1].contains("SECOND DETAIL"))
        XCTAssertTrue(bodies[1].contains("ENVELOPE-NUMBER"))
        XCTAssertFalse(bodies[1].contains("FIRST DETAIL"))
    }

    func testVoucherUncapturedBranchesDoNotReuseVNDLayout() throws {
        let source = try String(contentsOf: Fixtures.url("voucher_ct01"), encoding: .utf8)
        for version in ["1.0.0", "3.0.0", "4.0.0", "4.0.2"] {
            let xml = source.replacingOccurrences(of: "<PBAN_TLIEU_XML>4.0.1</PBAN_TLIEU_XML>", with: "<PBAN_TLIEU_XML>\(version)</PBAN_TLIEU_XML>")
            XCTAssertNil(VoucherRenderer(document: try document(xml)).render())
        }
        for currency in ["USD", "00000", "EUR"] {
            let xml = source.replacingOccurrences(of: "<MA_NGUYENTE>VND</MA_NGUYENTE>", with: "<MA_NGUYENTE>\(currency)</MA_NGUYENTE>")
            XCTAssertNil(VoucherRenderer(document: try document(xml)).render())
        }
        let negative = source.replacingOccurrences(of: "<TONG_TIEN>1234580235</TONG_TIEN>", with: "<TONG_TIEN>-1234580235</TONG_TIEN>")
        XCTAssertNil(VoucherRenderer(document: try document(negative)).render())
    }
}
