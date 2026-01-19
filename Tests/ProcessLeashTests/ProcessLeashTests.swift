// Copyright (C) 2026 ProcessLeash contributors
// Licensed under the GNU General Public License v3.0

import XCTest
@testable import ProcessLeash

final class ProcessLeashTests: XCTestCase {
    @MainActor
    func testResetAllResetsPercentToDefault() {
        let model = AppModel()
        let app = RunningApp(id: 1234, name: "TestApp", icon: nil, bundleIdentifier: nil)

        let limiter = model.limiter(for: app)
        limiter.percent = 42

        model.resetAllToDefault()

        XCTAssertEqual(limiter.percent, model.defaultPercent)
        XCTAssertFalse(limiter.isRunning)
    }
}
