import XCTest
@testable import iTaxViewerCore

final class CoverageSafetyTests: XCTestCase {
    func testWithholdingHeaderKeepsReferenceContactGroupsAndLegalCitation() throws {
        let document = try Fixtures.document("tncn_394_05kk_tt92")
        let registry = try FormRegistry.bundled()
        let classification = try DocumentClassifier.classify(document, registry: registry)
        let html = HTMLRenderer(registry: registry).render(document: document, classification: classification).html
        let rows = html.components(separatedBy: "</tr>")
        XCTAssertTrue(rows.contains { $0.contains("[07]") && $0.contains("[08]") })
        XCTAssertTrue(rows.contains { $0.contains("[09]") && $0.contains("[10]") && $0.contains("[11]") })
        XCTAssertTrue(rows.contains { $0.contains("[17]") && $0.contains("[18]") && $0.contains("[19]") })
        XCTAssertTrue(html.contains("92/2015/TT-BTC"))
    }
    private func load(_ xml: String) throws -> TaxDocument {
        try TaxDocument.load(data: Data(xml.utf8), sourceName: "synthetic.xml")
    }

    func testDefaultNamespaceDoesNotBecomeAnElementPrefix() throws {
        let plain = try load("<TBaoThueDTu xmlns=\"urn:test\"><child/></TBaoThueDTu>")
        XCTAssertNil(plain.root.prefix)
        XCTAssertNil(plain.root.children.first?.prefix)
        XCTAssertEqual(plain.root.namespaceURI, "urn:test")
        let prefixed = try load("<n:TBaoThueDTu xmlns:n=\"urn:test\"/>")
        XCTAssertEqual(prefixed.root.prefix, "n")
        XCTAssertEqual(prefixed.root.localName, "TBaoThueDTu")
    }

    func testNoticeCodesDoNotResolveThroughDeclarationCatalog() throws {
        let document = try Fixtures.document("notice_844")
        let registry = try FormRegistry.bundled()
        let classification = try DocumentClassifier.classify(document, registry: registry)
        XCTAssertEqual(classification.registryCode, "844")
        XCTAssertNotEqual(classification.displayCode, "02/GTGT")
        XCTAssertEqual(registry.documentEntry(root: "TBaoThueDTu", code: "844", version: "2.4.9")?.kind, "notice")
        XCTAssertNil(registry.documentEntry(root: "CHUNGTU", code: "844", version: "2.4.9"))
    }

    func testVersionBoundLayoutsDoNotConsumeOtherRevisions() throws {
        let registry = try FormRegistry.bundled()
        for (code, version) in [("864", "2.8.3"), ("395", "2.1.6"), ("07", "2.1.2"), ("847", "99.0.0")] {
            XCTAssertNil(registry.resolve(code: code, version: version, filingType: "C"))
        }
        XCTAssertEqual(registry.resolve(code: "864", version: "2.9.3", filingType: "C")?.maTKhai, "864")
    }

    func testFallbackPreservesMoreThanEightHundredOrFiveThousandFields() throws {
        let rows = (0..<5_100).map { "<row><value>MARKER_\($0)_END</value></row>" }.joined()
        let document = try load("<DanhMucDTu>\(rows)</DanhMucDTu>")
        let registry = try FormRegistry.bundled()
        let classification = try DocumentClassifier.classify(document, registry: registry)
        let html = HTMLRenderer(registry: registry).render(document: document, classification: classification).html
        XCTAssertTrue(html.contains("MARKER_800_END"))
        XCTAssertTrue(html.contains("MARKER_5099_END"))
        XCTAssertEqual(html.components(separatedBy: "class=\"path\"").count - 1, 5_100)
    }

    func testRegistrationUsesNestedCaseSensitiveVersionField() throws {
        let document = try load("<DKyThueDTu><DKyThue><TTinChung><maDKy>219</maDKy><pBanDKy>2.0.9</pBanDKy></TTinChung></DKyThue></DKyThueDTu>")
        XCTAssertEqual(document.metadata.formCode, "219")
        XCTAssertEqual(document.metadata.formVersion, "2.0.9")
    }

    func testCustomsEnvelopeAndOtherKnownRootsRemainAccessible() throws {
        let registry = try FormRegistry.bundled()
        let envelope = try load("<s:Envelope xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\"><s:Body><ExImCode>TEST</ExImCode></s:Body></s:Envelope>")
        XCTAssertEqual(try DocumentClassifier.classify(envelope, registry: registry).kind, .customs)
        XCTAssertEqual(envelope.metadata.customsCode, "TEST")
        for root in ["TRASOAT_THUE", "XULY_NTHUA", "XACNHAN_THUE", "XACNHAN_NVTHUE", "TBTNhan"] {
            let document = try load("<\(root)/>")
            XCTAssertEqual(try DocumentClassifier.classify(document, registry: registry).kind, .notice)
        }
    }
}
