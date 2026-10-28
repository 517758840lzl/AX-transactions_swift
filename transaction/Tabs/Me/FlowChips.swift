import Combine
import SwiftUI

struct FlowChips: View {
    var names: [String]
    var editing: Bool
    var canRemove: Bool
    var onRemove: (String) -> Void

    var body: some View {
        FlexibleChips(names: names, editing: editing, canRemove: canRemove, onRemove: onRemove)
    }
}
