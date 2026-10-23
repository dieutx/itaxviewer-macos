import XCTest
@testable import iTaxViewerCore

final class FinancialStatementTests: XCTestCase {
    private func fixture(_ code: String, transform: ((String) -> String)? = nil) throws -> TaxDocument {
        let url = try Fixtures.url("financial_\(code)_static")
        guard let transform else { return try TaxDocument.load(url: url) }
        let xml = try String(contentsOf: url, encoding: .utf8)
        return try TaxDocument.load(data: Data(transform(xml).utf8), sourceName: "financial_\(code)_synthetic.xml")
    }

    private func rendered(_ document: TaxDocument) throws -> (FormSpec, String) {
        let registry = try FormRegistry.bundled()
        let classification = try DocumentClassifier.classify(document, registry: registry)
        guard case .full(let spec) = classification.support else {
            throw NSError(domain: "FinancialStatementTests", code: 1)
        }
        return (spec, HTMLRenderer(registry: registry).render(document: document, classification: classification).html)
    }

    func testFinancialTablesContainEveryMappedValueInBothYearsAndRawNotes() throws {
        for (code, expectedRows) in [("701", 34), ("702", 18), ("1254", 66)] {
            let document = try fixture(code)
            let (spec, html) = try rendered(document)
            XCTAssertEqual(spec.rows.count, expectedRows)
            XCTAssertEqual(spec.tableHeaders?.count, 6)
            XCTAssertTrue(html.contains("class=\"tax-table bctc-table\""))
            let main = try XCTUnwrap(document.root.firstDescendant(named: "CTieuTKhaiChinh"))
            for row in spec.rows {
                XCTAssertEqual(row.values.count, 3)
                for value in row.values {
                    let raw = try XCTUnwrap(main.node(atLocalPath: value.path)?.trimmedValue)
                    let expected = value.path.hasPrefix("ThuyetMinh/") ? raw : VietnameseFormat.number(raw)
                    XCTAssertTrue(html.contains(VietnameseFormat.htmlEscape(expected)),
                                  "Missing financial field in \(code): \(value.path)")
                }
            }
            XCTAssertTrue(html.contains(">001.01</td>"), "Explanatory references must retain leading zeros and dot")
            XCTAssertTrue(html.contains("Số cuối năm"))
            XCTAssertTrue(html.contains("Số đầu năm"))
        }
    }

    func testFinancialHeadersUseStatementDateAndVersionSpecificEntityBlocks() throws {
        for code in ["701", "702", "1254"] {
            let (_, html) = try rendered(try fixture(code))
            XCTAssertTrue(html.contains("BÁO CÁO TÌNH HÌNH TÀI CHÍNH"))
            XCTAssertTrue(html.contains("Tại ngày 31 tháng 12 năm 2025"))
            XCTAssertFalse(html.contains("Kỳ tính thuế:"))
            if code == "1254" {
                XCTAssertTrue(html.contains("CƠ QUAN CHỦ QUẢN MẪU"))
                XCTAssertTrue(html.contains("24/2024/TT-BTC"))
            } else {
                XCTAssertTrue(html.contains("[01] Tên người nộp thuế:"))
                XCTAssertTrue(html.contains("BCTC đã được kiểm toán: [x]"))
                XCTAssertTrue(html.contains("Ý KIẾN KIỂM TOÁN MẪU"))
                XCTAssertTrue(html.contains("107/2017/TT-BTC"))
            }
        }
    }

    func testFinancialFooterReadsExactCaseSensitiveRepresentativePaths() throws {
        let (_, simple) = try rendered(try fixture("702") { xml in
            xml.replacingOccurrences(of: "<thuTruongdonVi>ĐẠI DIỆN MẪU</thuTruongdonVi>",
                                     with: "<thuTruongdonVi>ĐẠI DIỆN MẪU 702</thuTruongdonVi>")
        })
        XCTAssertTrue(simple.contains("class=\"bctc-signature-name\">ĐẠI DIỆN MẪU 702</div>"))
        XCTAssertTrue(simple.contains("NGƯỜI ĐẠI DIỆN THEO PHÁP LUẬT"))
        let (_, modern) = try rendered(try fixture("1254"))
        XCTAssertTrue(modern.contains("THỦ TRƯỞNG ĐƠN VỊ"))
        XCTAssertTrue(modern.contains("class=\"bctc-signature-name\">NGƯỜI LẬP MẪU</div>"))
        XCTAssertTrue(modern.contains("Lập, ngày 28 tháng 02 năm 2026"))
    }

    func testNegativeAmountsAreFormattedWithoutFormattingExplanatoryReferences() throws {
        let (_, html) = try rendered(try fixture("701") { xml in
            xml.replacingOccurrences(of: ">701100001<", with: ">-701100001.25<")
        })
        XCTAssertTrue(html.contains("(701.100.001,25)"))
        XCTAssertTrue(html.contains(">001.01</td>"))
    }

    func testUnmappedFinancialDataIsEscapedAndNeverSilentlyTruncated() throws {
        let document = try fixture("701") { xml in
            let many = (0..<5_100).map { "<Extra>FINANCIAL-EXTRA-\($0)</Extra>" }.joined()
            let escaped = "<Unmapped>&lt;img src=x onerror=alert(1)&gt;</Unmapped>"
            return xml.replacingOccurrences(of: "</CTieuTKhaiChinh>", with: many + escaped + "</CTieuTKhaiChinh>")
        }
        let (_, html) = try rendered(document)
        XCTAssertTrue(html.contains("Dữ liệu khác chưa có ánh xạ bố cục"))
        XCTAssertTrue(html.contains("FINANCIAL-EXTRA-5099"))
        XCTAssertTrue(html.contains("&lt;img src=x onerror=alert(1)&gt;"))
        XCTAssertFalse(html.contains("<img src=x"))
    }

    func testFinancialLayoutRejectsUninspectedVersionAndMismatchedSpec() throws {
        let original = try fixture("701")
        let (spec, _) = try rendered(original)
        let unsupported = try fixture("701") { $0.replacingOccurrences(of: "<pbanTKhaiXML>2.3.5</pbanTKhaiXML>",
                                                                     with: "<pbanTKhaiXML>99.0.0</pbanTKhaiXML>") }
        XCTAssertFalse(FinancialStatementRenderer.supports(document: unsupported))
        XCTAssertNil(FinancialStatementRenderer(document: unsupported, spec: spec).render())
        let other = try fixture("702")
        XCTAssertNil(FinancialStatementRenderer(document: other, spec: spec).render())
        let registry = try FormRegistry.bundled()
        let classification = try DocumentClassifier.classify(unsupported, registry: registry)
        XCTAssertFalse(classification.support.isFull)
    }
}
