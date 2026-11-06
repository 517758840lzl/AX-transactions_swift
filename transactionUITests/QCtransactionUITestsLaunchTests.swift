//
//  QCtransactionUITestsLaunchTests.swift
//  QCtransactionUITests
//
//  Created by Lzl on 2026/9/30.
//

import XCTest

final class QCtransactionUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Um screenshot depois do arranque, para comparar o ecrã inicial antes e depois das alterações
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
