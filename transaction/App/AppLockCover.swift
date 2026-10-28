import LocalAuthentication
import SwiftUI

struct AppLockCover: View {
    var title: String
    var retry: String
    var onUnlock: () -> Void

    var body: some View {
        VStack(spacing: 22) {
            Text(title)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            Button(retry) { ask() }
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Palette.ink)
                .padding(.horizontal, 22)
                .frame(minHeight: 48)
                .background(Palette.pink, in: Capsule())
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.ink)
        .onAppear { ask() }
    }

    private func ask() {
        let context = LAContext()
        var failure: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &failure) else {
            onUnlock()
            return
        }
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: title) { ok, _ in
            guard ok else { return }
            DispatchQueue.main.async { onUnlock() }
        }
    }
}
