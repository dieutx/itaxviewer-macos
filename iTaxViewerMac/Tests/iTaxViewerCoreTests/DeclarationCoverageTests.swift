import XCTest
@testable import iTaxViewerCore

final class DeclarationCoverageTests: XCTestCase {
    private func rendered(_ code: String) throws -> (TaxDocument, FormSpec, String) {
        let document = try Fixtures.document("declaration_\(code)_static")
        let registry = try FormRegistry.bundled()
        let classification = try DocumentClassifier.classify(document, registry: registry)
        guard case .full(let spec) = classification.support else {
            throw NSError(domain: "DeclarationCoverage", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Missing declaration mapping \(code)"])
        }
        let html = HTMLRenderer(registry: registry).render(document: document,
                                                         classification: classification).html
        return (document, spec, html)
    }

    func testEveryNewMappedAmountAppearsInRenderedForm() throws {
        for code in ["864", "395", "07", "847"] {
            let (document, spec, html) = try rendered(code)
            XCTAssertEqual(spec.maTKhai, code)
            let main = try XCTUnwrap(document.root.firstDescendant(named: "CTieuTKhaiChinh"))
            for row in spec.rows {
                for value in row.values {
                    let base: iTaxViewerCore.XMLNode?
                    switch value.root {
                    case "ktru": base = main.firstChild(named: "NVuKhauTruThue")
                    case "qtoan": base = main.firstChild(named: "NVuQToanThay")
                    default: base = main
                    }
                    let raw = try XCTUnwrap(base?.node(atLocalPath: value.path)?.trimmedValue)
                    XCTAssertTrue(html.contains(VietnameseFormat.number(raw)),
                                  "Missing rendered indicator in \(code): \(row.indicator)")
                }
            }
            XCTAssertFalse(html.contains("class=\"path\""))
        }
    }

    func testTT80WithholdingUsesCurrencyFromIndicator21AndNew251() throws {
        let (_, spec, html) = try rendered("864")
        XCTAssertEqual(spec.rows.first { $0.indicator == "20" }?.unit, "Người")
        XCTAssertEqual(spec.rows.first { $0.indicator == "21" }?.unit, "VNĐ")
        XCTAssertTrue(html.contains("[25.1]"))
        let row = try XCTUnwrap(html.components(separatedBy: "</tr>").first { $0.contains("[21]") })
        XCTAssertTrue(row.contains("VNĐ"))
        XCTAssertFalse(row.contains(">Người<"))
    }

    func testLegacyFinalisationUsesSeparateNumberingAndAuthorisedPeopleUnit() throws {
        let (_, spec, html) = try rendered("395")
        XCTAssertEqual(spec.rows.first?.indicator, "21")
        XCTAssertEqual(spec.rows.last?.indicator, "46")
        let authorised = try XCTUnwrap(spec.rows.first { $0.indicator == "42" })
        XCTAssertEqual(authorised.values.first?.root, "qtoan")
        XCTAssertEqual(authorised.unit, "Người")
        let row = try XCTUnwrap(html.components(separatedBy: "</tr>").first { $0.contains("[42]") })
        XCTAssertTrue(row.contains("Người"))
        XCTAssertTrue(html.contains("Chuyển đổi dữ liệu mẫu"))
    }

    func testDirectVATKeepsSharedRevenueAndBelowTableTotals() throws {
        let (_, _, html) = try rendered("07")
        XCTAssertTrue(html.contains("[21]"))
        XCTAssertTrue(html.contains("[32]"))
        XCTAssertTrue(html.contains("[33]"))
        XCTAssertTrue(html.contains("rowspan=\"5\""))
        XCTAssertFalse(html.contains("☒"))
    }

    func testTT80DirectVATIncludesCollectionRecordsAndTotals() throws {
        let (_, _, html) = try rendered("847")
        XCTAssertTrue(html.contains("Khoản thu hộ mẫu"))
        XCTAssertTrue(html.contains("1.200.000"))
        XCTAssertTrue(html.contains("120.000"))
        XCTAssertTrue(html.contains("[36]"))
        XCTAssertTrue(html.contains("[37]"))
    }
}
