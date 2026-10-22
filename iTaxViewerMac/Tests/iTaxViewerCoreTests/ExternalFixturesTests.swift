import XCTest
@testable import iTaxViewerCore

/// Optional integration test over a local directory of real tax XML files.
///
/// The files stay on the Mac and are never committed. Only file names, form codes
/// and field counts are printed; taxpayer values are never logged.
///
///     ITAX_FIXTURE_DIR=~/itax-samples swift test --filter ExternalFixturesTests
final class ExternalFixturesTests: XCTestCase {

    func testExternalDirectoryIfConfigured() throws {
        guard let configured = ProcessInfo.processInfo.environment["ITAX_FIXTURE_DIR"] else {
            throw XCTSkip("Set ITAX_FIXTURE_DIR to a local folder of tax XML files")
        }
        let directory = URL(fileURLWithPath: (configured as NSString).expandingTildeInPath)
        var files: [URL] = []
        // `test-data/` and real sample folders keep files in subdirectories, so
        // walk recursively instead of only looking at the top level.
        if let walker = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) {
            for case let url as URL in walker where url.pathExtension.lowercased() == "xml" {
                files.append(url)
            }
        }
        files.sort { $0.lastPathComponent < $1.lastPathComponent }

        XCTAssertFalse(files.isEmpty, "No .xml files in \(directory.path)")

        let registry = try FormRegistry.bundled()
        var failures: [String] = []

        for file in files {
            do {
                let document = try TaxDocument.load(url: file)
                let classification = try DocumentClassifier.classify(document, registry: registry)
                let fields = document.root.leaves().count
                print("OK \(file.lastPathComponent) | \(classification.displayCode ?? "—") | "
                      + "\(classification.kind.rawValue) | fields=\(fields)")
            } catch {
                failures.append("\(file.lastPathComponent): \(error.localizedDescription)")
            }
        }

        XCTAssertTrue(failures.isEmpty, failures.joined(separator: "\n"))
    }
}
