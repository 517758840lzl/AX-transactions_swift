//
//  QCPageBack.swift
//  transaction
//
//  Created by Lzl on 2026/10/2.
//

import SwiftUI

private struct QCPageBackKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

private struct QCAmountsHiddenKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var pageBack: () -> Void {
        get { self[QCPageBackKey.self] }
        set { self[QCPageBackKey.self] = newValue }
    }

    var amountsHidden: Bool {
        get { self[QCAmountsHiddenKey.self] }
        set { self[QCAmountsHiddenKey.self] = newValue }
    }
}
