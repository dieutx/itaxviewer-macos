import AppKit
import XCTest
@testable import iTaxViewerCore

final class NativePrintSettingsTests: XCTestCase {
    @MainActor
    func testExportResetsInheritedPageRangeWithoutChangingPreviousJob() {
        let previous = NSPrintInfo()
        previous.dictionary()[NSPrintInfo.AttributeKey.allPages] = false
        previous.dictionary()[NSPrintInfo.AttributeKey.firstPage] = 2
        previous.dictionary()[NSPrintInfo.AttributeKey.lastPage] = 2
        let oldURL = URL(fileURLWithPath: "/tmp/previous.pdf")
        previous.jobDisposition = .save
        previous.dictionary()[NSPrintInfo.AttributeKey.jobSavingURL] = oldURL
        let destination = URL(fileURLWithPath: "/tmp/complete.pdf")

        let info = NativePrintSettings.make(orientation: .portrait, savingTo: destination, base: previous)

        XCTAssertEqual(info.dictionary()[NSPrintInfo.AttributeKey.allPages] as? Bool, true)
        // AppKit materializes these defaults when dictionary() is read again.
        XCTAssertEqual(info.dictionary()[NSPrintInfo.AttributeKey.firstPage] as? Int, 1)
        XCTAssertEqual(info.dictionary()[NSPrintInfo.AttributeKey.lastPage] as? Int, Int.max)
        XCTAssertEqual(info.jobDisposition, .save)
        XCTAssertEqual(info.dictionary()[NSPrintInfo.AttributeKey.jobSavingURL] as? URL, destination)
        XCTAssertFalse(info === previous)
        XCTAssertEqual(previous.dictionary()[NSPrintInfo.AttributeKey.allPages] as? Bool, false)
        XCTAssertEqual(previous.dictionary()[NSPrintInfo.AttributeKey.jobSavingURL] as? URL, oldURL)
    }

    @MainActor
    func testPrintClearsPreviousPDFDestinationAndRestoresA4Margins() {
        let previous = NSPrintInfo()
        previous.jobDisposition = .save
        previous.dictionary()[NSPrintInfo.AttributeKey.jobSavingURL] = URL(fileURLWithPath: "/tmp/previous.pdf")
        previous.paperSize = NSSize(width: 100, height: 100)
        previous.topMargin = 0
        previous.bottomMargin = 0
        let mm = 72.0 / 25.4

        let orientations: [PageOrientation] = [.portrait, .landscape]
        for orientation in orientations {
            let info = NativePrintSettings.make(orientation: orientation, base: previous)
            XCTAssertEqual(info.jobDisposition, .spool)
            XCTAssertNil(info.dictionary()[NSPrintInfo.AttributeKey.jobSavingURL])
            XCTAssertEqual(info.paperSize.width, (orientation == .portrait ? 210 : 297) * mm, accuracy: 1)
            XCTAssertEqual(info.paperSize.height, (orientation == .portrait ? 297 : 210) * mm, accuracy: 1)
            XCTAssertEqual(info.topMargin, 20 * mm, accuracy: 0.01)
            XCTAssertEqual(info.leftMargin, 20 * mm, accuracy: 0.01)
            XCTAssertEqual(info.rightMargin, 20 * mm, accuracy: 0.01)
            XCTAssertEqual(info.bottomMargin, 10 * mm, accuracy: 0.01)
        }
    }
}
