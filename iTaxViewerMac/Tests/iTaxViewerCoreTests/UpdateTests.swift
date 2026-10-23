import XCTest
@testable import iTaxViewerCore

final class AppVersionTests: XCTestCase {

    func testOfflineBuildRefusesReleaseFetch() async {
        do {
            _ = try await GitHubReleaseClient().latestRelease(currentVersion: "1.0.0")
            XCTFail("Offline build must not fetch a release")
        } catch UpdateError.offlineMode {
            // Expected: no URLRequest is constructed by the client.
        } catch {
            XCTFail("Expected deterministic offline refusal")
        }
    }

    func testNewerPatchAndMinor() {
        XCTAssertTrue(AppVersion.isNewer("1.0.1", than: "1.0.0"))
        XCTAssertTrue(AppVersion.isNewer("1.2.0", than: "1.1.9"))
        XCTAssertTrue(AppVersion.isNewer("2.0", than: "1.9.9"))
        XCTAssertFalse(AppVersion.isNewer("1.0.0", than: "1.0.0"))
        XCTAssertFalse(AppVersion.isNewer("1.0", than: "1.0.0"))
        XCTAssertFalse(AppVersion.isNewer("1.0.0", than: "1.0.1"))
    }

    func testTagNormalisationAndPrereleaseCore() {
        XCTAssertEqual(GitHubReleaseClient.normalizedVersion("v1.4.2"), "1.4.2")
        XCTAssertTrue(AppVersion.isNewer("1.4.2-beta.1", than: "1.4.1"))
        XCTAssertFalse(AppVersion.isNewer("1.4.2-beta.1", than: "1.4.2"))
    }

    func testInvalidComponentsFallBackToZero() {
        XCTAssertTrue(AppVersion.isNewer("1.0.1", than: "1.0.x"))
        XCTAssertFalse(AppVersion.isNewer("", than: "1.0.0"))
    }
}
