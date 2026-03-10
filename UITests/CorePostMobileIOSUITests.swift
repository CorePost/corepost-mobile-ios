import XCTest

final class CorePostMobileIOSUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchEnvironment["DEMO_MODE"] = "1"
        app.launchEnvironment["UITEST_RESET_STATE"] = "1"
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testDemoFlow() throws {
        let onboardingButton = app.buttons["onboarding.openSettingsButton"]
        XCTAssertTrue(onboardingButton.waitForExistence(timeout: 10))
        captureScreenshot(named: "01-onboarding")
        onboardingButton.tap()

        let applySeedButton = app.buttons["settings.applyDemoSeedButton"]
        XCTAssertTrue(applySeedButton.waitForExistence(timeout: 10))
        captureScreenshot(named: "02-settings")
        applySeedButton.tap()
        sleep(1)

        let createButton = app.buttons["settings.createDemoProfileButton"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 5))
        createButton.tap()

        let refreshButton = app.buttons["dashboard.refreshStatusButton"]
        XCTAssertTrue(refreshButton.waitForExistence(timeout: 20))
        XCTAssertTrue(waitForText("Профиль готов", timeout: 20))
        captureScreenshot(named: "03-dashboard-ready")
        sleep(2)
        refreshButton.tap()
        sleep(2)

        let primaryActionButton = app.buttons["dashboard.primaryActionButton"]
        XCTAssertTrue(primaryActionButton.waitForExistence(timeout: 5))
        primaryActionButton.tap()
        XCTAssertTrue(waitForText("Нужно подтверждение", timeout: 20))
        captureScreenshot(named: "04-pending-lock")
        sleep(3)

        primaryActionButton.tap()
        XCTAssertTrue(waitForText("Устройство заблокировано", timeout: 20))
        captureScreenshot(named: "05-locked")
        sleep(3)

        primaryActionButton.tap()
        XCTAssertTrue(waitForText("Доступ восстановлен", timeout: 20))
        captureScreenshot(named: "06-recovered")
        sleep(3)
    }

    private func waitForText(_ text: String, timeout: TimeInterval) -> Bool {
        let target = app.staticTexts[text].firstMatch
        return target.waitForExistence(timeout: timeout)
    }

    private func captureScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
