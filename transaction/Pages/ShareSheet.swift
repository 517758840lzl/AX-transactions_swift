import UIKit

enum ShareSheet {
    static func present(_ text: String) {
        let controller = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first(where: \.isKeyWindow)?.rootViewController else { return }
        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        top.present(controller, animated: true)
    }
}
