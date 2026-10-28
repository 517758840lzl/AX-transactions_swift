//
//  PageBack.swift
//  transaction
//
//  Created by Lzl on 2026/10/2.
//

import SwiftUI

private struct PageBackKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

private struct KeyboardDoneKey: EnvironmentKey {
    static let defaultValue = "Done"
}

private struct AmountsHiddenKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var pageBack: () -> Void {
        get { self[PageBackKey.self] }
        set { self[PageBackKey.self] = newValue }
    }

    var keyboardDone: String {
        get { self[KeyboardDoneKey.self] }
        set { self[KeyboardDoneKey.self] = newValue }
    }

    var amountsHidden: Bool {
        get { self[AmountsHiddenKey.self] }
        set { self[AmountsHiddenKey.self] = newValue }
    }
}
