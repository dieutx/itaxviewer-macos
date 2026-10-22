import XCTest
@testable import iTaxViewerCore

enum Fixtures {
    static func url(_ name: String) throws -> URL {
        guard let url = Bundle.module.url(forResource: name, withExtension: "xml", subdirectory: "Fixtures") else {
            throw NSError(domain: "Fixtures", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Missing fixture \(name).xml"])
        }
        return url
    }

    static func document(_ name: String) throws -> TaxDocument {
        try TaxDocument.load(url: try url(name))
    }
}

final class ParserTests: XCTestCase {

    func testParsesUTF8Declaration() throws {
        let doc = try Fixtures.document("gtgt_842_return")
        XCTAssertEqual(doc.root.localName, "HSoThueDTu")
        XCTAssertEqual(doc.metadata.formCode, "842")
        XCTAssertEqual(doc.metadata.formVersion, "2.8.3")
        XCTAssertEqual(doc.metadata.taxpayerTaxCode, "0000000000")
        XCTAssertEqual(doc.metadata.period, "06/2025")
    }

    func testParsesUTF16WithBOM() throws {
        let doc = try Fixtures.document("gtgt_842_return_utf16")
        XCTAssertEqual(doc.metadata.formCode, "842")
        XCTAssertTrue(doc.metadata.title?.contains("GIÁ TRỊ GIA TĂNG") == true)
    }

    func testRejectsXXEAndDoctype() throws {
        let url = try Fixtures.url("xxe_attack")
        XCTAssertThrowsError(try TaxDocument.load(url: url)) { error in
            XCTAssertEqual(error as? XMLInspectionError, XMLInspectionError.doctypeForbidden)
        }
    }

    func testRejectsMalformedXML() {
        let data = Data("<HSoThueDTu><unclosed>".utf8)
        XCTAssertThrowsError(try SecureXMLParser.parse(data: data))
    }

    func testRejectsOversizedDocument() {
        let data = Data(repeating: 0x20, count: 1024)
        let limits = XMLSecurityLimits(maxBytes: 128)
        XCTAssertThrowsError(try SecureXMLParser.parse(data: data, limits: limits)) { error in
            XCTAssertEqual(error as? XMLInspectionError, XMLInspectionError.documentTooLarge(limit: 128))
        }
    }

    func testNodeLookupIsNamespaceInsensitive() throws {
        let doc = try Fixtures.document("gtgt_842_return")
        let ct = doc.root.firstDescendant(named: "CTieuTKhaiChinh")
        XCTAssertEqual(ct?.node(atLocalPath: "GiaTriVaThueGTGTHHDVMuaVao/ct23")?.trimmedValue, "1000000000")
        XCTAssertNil(ct?.node(atLocalPath: "does/not/exist"))
    }
}

