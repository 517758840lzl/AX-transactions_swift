import SwiftUI

private struct PageBackKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

private struct KeyboardDoneKey: EnvironmentKey {
    static let defaultValue = "Done"
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
}
