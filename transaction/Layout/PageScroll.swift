import Combine
import SwiftUI

struct PageScroll<Content: View>: View {
    var bottom: CGFloat = 28
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) {
                content()
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
            .padding(.bottom, bottom)
            .immediateScroll()
        }
        .background(Palette.stage)
    }
}
