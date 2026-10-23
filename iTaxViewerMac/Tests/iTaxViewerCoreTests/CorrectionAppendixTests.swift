import XCTest
@testable import iTaxViewerCore

final class CorrectionAppendixTests: XCTestCase {
    private func render(_ document: TaxDocument) throws -> RenderedDocument {
        let registry = try FormRegistry.bundled()
        return HTMLRenderer(registry: registry).render(document: document,
            classification: try DocumentClassifier.classify(document, registry: registry))
    }

    func testCorrectionAndExplanationUseTheirOwnStructuresAndTotals() throws {
        let output = try render(Fixtures.document("correction_tt80"))
        XCTAssertTrue(output.html.contains("TỜ KHAI BỔ SUNG"))
        XCTAssertTrue(output.html.contains("BẢN GIẢI TRÌNH KHAI BỔ SUNG"))
        for amount in ["(1.234.567)", "2.345.678", "345.678", "456.789", "567.890", "678.901", "789.012", "(890.123)", "901.234", "123.450", "(234.560)"] {
            XCTAssertTrue(output.html.contains(amount))
        }
        XCTAssertTrue(output.html.contains("01/06/2025"))
        XCTAssertTrue(output.html.contains("Tài liệu bổ sung mẫu"))
        XCTAssertTrue(output.warnings.contains { $0.contains("TT80") })
    }

    func testUnknownCorrectionExtensionsAreEscapedAndPreserved() throws {
        let output = try render(Fixtures.document("correction_tt80"))
        XCTAssertTrue(output.html.contains("Dữ liệu XML bổ sung ngoài bố cục biểu mẫu"))
        XCTAssertTrue(output.html.contains("EXTRA-MARKER &lt;b&gt;escaped&lt;/b&gt;"))
        XCTAssertFalse(output.html.contains("EXTRA-MARKER <b>escaped</b>"))
    }

    func testUnknownParentVersionRetainsStructuredAppendix() throws {
        let source = try String(contentsOf: Fixtures.url("correction_tt80"), encoding: .utf8)
        let xml = source.replacingOccurrences(of: "<pbanTKhaiXML>2.5.1</pbanTKhaiXML>", with: "<pbanTKhaiXML>99.0.0</pbanTKhaiXML>")
        let document = try TaxDocument.load(data: Data(xml.utf8), sourceName: "synthetic.xml")
        let output = try render(document)
        XCTAssertTrue(output.html.contains("class=\"appendix-tree\""))
        XCTAssertTrue(output.html.contains("EXTRA-MARKER"))
        XCTAssertTrue(output.warnings.contains { $0.contains("chưa có bố cục in chuyên biệt") })
    }
}
