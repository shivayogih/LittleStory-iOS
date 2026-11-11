import XCTest

/// Runs on every simulator in CI (an iPhone and an iPad). Elements are found by accessibility
/// identifier, never by English text.
final class LaunchUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchShowsTitleAndTagline() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["app.launch.title"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["app.launch.tagline"].exists)
    }

    @MainActor
    func testLaunchInKannada() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(kn)", "-AppleLocale", "kn_IN"]
        app.launch()
        let tagline = app.staticTexts["app.launch.tagline"]
        XCTAssertTrue(tagline.waitForExistence(timeout: 10))
        XCTAssertEqual(tagline.label, "ಪ್ರತಿ ದಿನವೂ ಒಂದು ಕಥೆ")
    }

    @MainActor
    func testLaunchInLandscape() {
        let app = XCUIApplication()
        app.launch()
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(app.staticTexts["app.launch.title"].waitForExistence(timeout: 10))
        XCUIDevice.shared.orientation = .portrait
    }
}
