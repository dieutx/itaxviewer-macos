import XCTest
@testable import iTaxViewerCore

final class RegistryTests: XCTestCase {

    func testBundledRegistryMatchesShippedCatalog() throws {
        let registry = try FormRegistry.bundled()
        XCTAssertEqual(registry.source.application, "iTax Viewer")
        XCTAssertEqual(registry.source.entries, 1150)
        XCTAssertEqual(registry.source.formCodes, 410)
        XCTAssertEqual(Set(registry.supported.map(\.maTKhai)),
                       Set(["842", "394", "953", "892", "864", "395", "07", "847", "2002", "2003", "2004", "701", "702", "1254"]))
    }

    func testKnownDisplayCodes() throws {
        let registry = try FormRegistry.bundled()
        XCTAssertEqual(registry.codeInfo("842")?.displayCode, "01/GTGT")
        XCTAssertEqual(registry.codeInfo("394")?.displayCode, "05/KK-TNCN")
        XCTAssertEqual(registry.codeInfo("953")?.displayCode, "05/QTT-TNCN")
        XCTAssertEqual(registry.codeInfo("892")?.displayCode, "03/TNDN")
        XCTAssertEqual(registry.codeInfo("2006")?.displayCode, "06/TNCN")
    }

    func testVersionRewriteForLegacyForms() throws {
        let registry = try FormRegistry.bundled()
        XCTAssertEqual(registry.normalizedVersion(code: "42", version: "2.9.0"), "2.0.0")
        XCTAssertEqual(registry.normalizedVersion(code: "42", version: "2.0.8"), "2.0.8")
        XCTAssertEqual(registry.normalizedVersion(code: "842", version: "2.9.0"), "2.9.0")
    }

    func testSpecsContainOfficialIndicators() throws {
        let registry = try FormRegistry.bundled()
        let gtgt = try XCTUnwrap(registry.spec(for: "01/GTGT"))
        XCTAssertEqual(gtgt.rows.count, 27)
        XCTAssertTrue(gtgt.rows.contains { $0.indicator == "43" })
        XCTAssertTrue(gtgt.rows.contains { $0.kind == "checkbox" && $0.codes == ["21"] })

        let tndn = try XCTUnwrap(registry.spec(for: "03/TNDN"))
        XCTAssertGreaterThanOrEqual(tndn.rows.count, 70)
        XCTAssertTrue(tndn.rows.contains { $0.indicator == "B1" })
    }
}

final class ClassifierTests: XCTestCase {

    private func classify(_ fixture: String) throws -> (TaxDocument, Classification) {
        let doc = try Fixtures.document(fixture)
        let registry = try FormRegistry.bundled()
        return (doc, try DocumentClassifier.classify(doc, registry: registry))
    }

    func testGTGTDeclaration() throws {
        let (_, c) = try classify("gtgt_842_return")
        XCTAssertEqual(c.kind, .declaration)
        XCTAssertEqual(c.displayCode, "01/GTGT")
        XCTAssertEqual(c.registryCode, "842")
        XCTAssertEqual(c.orientation, .portrait)
        XCTAssertTrue(c.support.isFull)
    }

    func testLegacyGTGTCodeUsesFullRenderer() throws {
        let (_, c) = try classify("gtgt_01_legacy_212")
        XCTAssertEqual(c.kind, .declaration)
        XCTAssertEqual(c.displayCode, "01/GTGT")
        XCTAssertEqual(c.registryCode, "01")
        XCTAssertTrue(c.support.isFull)
        // The layout is reused, but the exact legacy version was not captured
        // on Windows, so the user must still see a warning.
        XCTAssertTrue(c.warnings.contains { $0.contains("2.1.2") })
    }

    func testLegacyGTGTResolutionDoesNotAffectKnownCodes() throws {
        let registry = try FormRegistry.bundled()
        XCTAssertEqual(registry.resolve(code: "01", version: "2.1.2", filingType: "C")?.maTKhai, "842")
        XCTAssertEqual(registry.resolve(code: "842", version: "2.8.3", filingType: "C")?.maTKhai, "842")
        XCTAssertNil(registry.resolve(code: "9999", version: "1.0.0", filingType: "C"))
    }

    func testTNCNKhaiThay() throws {
        let (_, c) = try classify("tncn_394_05kk_tt92")
        XCTAssertEqual(c.displayCode, "05/KK-TNCN")
        XCTAssertTrue(c.support.isFull)
        XCTAssertEqual(c.orientation, .portrait)
    }

    func testTNCNQuyetToan() throws {
        let (_, c) = try classify("tncn_953_05qtt")
        XCTAssertEqual(c.displayCode, "05/QTT-TNCN")
        XCTAssertTrue(c.support.isFull)
    }

    func testTNDN() throws {
        let (_, c) = try classify("tndn_892_03tndn_v2.9.4")
        XCTAssertEqual(c.displayCode, "03/TNDN")
        XCTAssertTrue(c.support.isFull)
    }

    func testPaymentVoucherIsGeneric() throws {
        let (_, c) = try classify("gnt_chungtu")
        XCTAssertEqual(c.kind, .paymentVoucher)
        if case .generic = c.support {} else { XCTFail("Expected generic support") }
    }

    func testTaxAuthorityNoticeIsGeneric() throws {
        let (_, c) = try classify("tbao_107_bstt")
        XCTAssertEqual(c.kind, .notice)
    }

    func testMissingRequiredFieldProducesReadableError() throws {
        let xml = """
        <HSoThueDTu><HSoKhaiThue><TTinChung><TTinTKhaiThue><TKhaiThue>
        <maTKhai>842</maTKhai><tenTKhai>x</tenTKhai><loaiTKhai>C</loaiTKhai>
        </TKhaiThue></TTinTKhaiThue></TTinChung><CTieuTKhaiChinh/></HSoKhaiThue></HSoThueDTu>
        """
        let doc = try TaxDocument.load(data: Data(xml.utf8), sourceName: "broken.xml")
        let registry = try FormRegistry.bundled()
        XCTAssertThrowsError(try DocumentClassifier.classify(doc, registry: registry)) { error in
            XCTAssertEqual(error as? DocumentError, DocumentError.missingField("pbanTKhaiXML"))
            XCTAssertTrue(error.localizedDescription.contains("pbanTKhaiXML"))
        }
    }

    func testUnknownRootIsRejected() throws {
        let doc = try TaxDocument.load(data: Data("<Something/>".utf8), sourceName: "x.xml")
        let registry = try FormRegistry.bundled()
        XCTAssertThrowsError(try DocumentClassifier.classify(doc, registry: registry))
    }
}

