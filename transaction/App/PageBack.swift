import SwiftUI

private struct PageBackKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var pageBack: () -> Void {
        get { self[PageBackKey.self] }
        set { self[PageBackKey.self] = newValue }
    }
}
