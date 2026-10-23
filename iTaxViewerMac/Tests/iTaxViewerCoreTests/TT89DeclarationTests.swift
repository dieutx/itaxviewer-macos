import XCTest
@testable import iTaxViewerCore

final class TT89DeclarationTests: XCTestCase {
    private func render(_ code: String) throws -> (TaxDocument, FormSpec, String) {
        let document = try Fixtures.document("declaration_\(code)_static")
        let registry = try FormRegistry.bundled()
        let classification = try DocumentClassifier.classify(document, registry: registry)
        guard case .full(let spec) = classification.support else {
            throw NSError(domain: "TT89", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing version-bound declaration layout"])
        }
        return (document, spec, HTMLRenderer(registry: registry).render(document: document, classification: classification).html)
    }

    func testTT89FormsKeepDistinctIndicatorRangesAndAmounts() throws {
        let cases: [(String, String, String)] = [("2002", "11", "18"), ("2003", "16", "26"), ("2004", "17", "22")]
        for (code, first, last) in cases {
            let (document, spec, html) = try render(code)
            XCTAssertEqual(spec.maTKhai, code)
            XCTAssertEqual(spec.versions, ["3.0.9"])
            XCTAssertEqual(spec.rows.first?.indicator, first)
            XCTAssertEqual(spec.rows.last?.indicator, last)
            let main = try XCTUnwrap(document.root.firstDescendant(named: "CTieuTKhaiChinh"))
            for row in spec.rows {
                for value in row.values {
                    let raw = try XCTUnwrap(main.node(atLocalPath: value.path)?.trimmedValue)
                    XCTAssertTrue(html.contains(VietnameseFormat.number(raw)), "A TT89 amount was omitted")
                }
            }
            XCTAssertTrue(html.contains("89/2026/TT-BTC"))
            XCTAssertFalse(html.contains("class=\"path\""))
        }
    }

    func testRevenueDetailsStayBetweenTotalRevenueAndTaxDue() throws {
        let (_, _, html) = try render("2002")
        let first = try XCTUnwrap(html.range(of: "200.200.011"))
        let details = try XCTUnwrap(html.range(of: "Doanh thu tổng hợp mẫu 1"))
        let next = try XCTUnwrap(html.range(of: "200.200.012"))
        XCTAssertLessThan(first.lowerBound, details.lowerBound)
        XCTAssertLessThan(details.lowerBound, next.lowerBound)
        XCTAssertTrue(html.contains("1.1"))
        XCTAssertTrue(html.contains("1.12"))
        XCTAssertTrue(html.contains("300.000.001"))
        XCTAssertTrue(html.contains("300.000.002"))
    }

    func testRealEstateContractDatesAndCompositeAddressAreVisible() throws {
        let (_, _, html) = try render("2003")
        XCTAssertTrue(html.contains("HĐ-MẪU-1"))
        XCTAssertTrue(html.contains("01/05/2026"))
        XCTAssertTrue(html.contains("02/05/2026"))
        XCTAssertTrue(html.contains("MẪU-2003-12-xaPhuong_ten"))
        XCTAssertTrue(html.contains("MẪU-2003-12-tinhTP_ten"))
        let contract = try XCTUnwrap(html.range(of: "HĐ-MẪU-1"))
        let agency = try XCTUnwrap(html.range(of: "MẪU-2003-10"))
        XCTAssertLessThan(contract.lowerBound, agency.lowerBound)
    }

    func testCapitalTransferRetainsSourceRateAndContractDate() throws {
        let (_, spec, html) = try render("2004")
        XCTAssertEqual(spec.rows.first { $0.indicator == "17" }?.kind, "summary")
        XCTAssertTrue(html.contains("2,5"))
        XCTAssertTrue(html.contains("30/06/2026"))
        XCTAssertTrue(html.contains("200.400.018"))
        XCTAssertTrue(html.contains("200.400.022"))
    }
}
