//
//  valas_swiftuiUITests.swift
//  valas-swiftuiUITests
//
//  Created by deni zakya on 27.12.25.
//

import XCTest

final class valas_swiftuiUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testAppLaunchesWithCurrencyConverter() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Verify the amount input exists
        let amountInput = app.textFields["amount_input"]
        XCTAssertTrue(amountInput.waitForExistence(timeout: 5))
        
        // Verify swap button exists
        let swapButton = app.buttons["swap_button"]
        XCTAssertTrue(swapButton.exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
