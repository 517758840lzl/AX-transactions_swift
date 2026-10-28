import Combine
import SwiftUI

struct FieldLabel: View {
    var text: String
    var body: some View {
        Text(text).font(.system(size: 13, weight: .bold)).foregroundStyle(Palette.ink)
    }
}
