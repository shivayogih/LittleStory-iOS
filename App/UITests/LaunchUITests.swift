import XCTest

/// Runs on every simulator in CI (an iPhone and an iPad). Elements are found by accessibility
/// identifier, never by English text. `-uiTest` starts each run with empty, in-memory data.
final class LaunchUITests: XCTestCase {
    private let timeout: TimeInterval = 10

    override func setUp() {
        continueAfterFailure = false
    }

    private func launch(_ extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-uiTest"] + extraArguments
        app.launch()
        return app
    }

    @MainActor
    func testFirstRunShowsOnboarding() {
        let app = launch()
        XCTAssertTrue(app.staticTexts["onboarding.title"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons["onboarding.continue"].exists)
        XCTAssertTrue(app.buttons["onboarding.skip"].exists)
    }

    @MainActor
    func testSkippingSetupOpensHome() {
        let app = launch()
        let skip = app.buttons["onboarding.skip"]
        XCTAssertTrue(skip.waitForExistence(timeout: timeout))
        skip.tap()
        let setupSkip = app.buttons["setup.skip"]
        XCTAssertTrue(setupSkip.waitForExistence(timeout: timeout))
        setupSkip.tap()
        XCTAssertTrue(app.staticTexts["home.title"].waitForExistence(timeout: timeout))
    }

    @MainActor
    func testCreatingAProfileGreetsTheChild() {
        let app = launch()
        let continueButton = app.buttons["onboarding.continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: timeout))
        for _ in 0 ..< 3 {
            continueButton.tap()
        }
        let name = app.textFields["setup.name"]
        XCTAssertTrue(name.waitForExistence(timeout: timeout))
        name.tap()
        name.typeText("Asha")
        app.buttons["setup.submit"].tap()
        let title = app.staticTexts["home.title"]
        XCTAssertTrue(title.waitForExistence(timeout: timeout))
        XCTAssertTrue(title.label.contains("Asha"))
    }

    @MainActor
    func testLaunchInKannada() {
        let app = launch(["-AppleLanguages", "(kn)", "-AppleLocale", "kn_IN"])
        let title = app.staticTexts["onboarding.title"]
        XCTAssertTrue(title.waitForExistence(timeout: timeout))
        XCTAssertEqual(title.label, "ಪ್ರತಿ ದಿನವೂ ಒಂದು ಕಥೆ")
    }

    @MainActor
    func testLaunchInLandscape() {
        let app = launch()
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        XCTAssertTrue(app.staticTexts["onboarding.title"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons["onboarding.continue"].isHittable)
    }
}
