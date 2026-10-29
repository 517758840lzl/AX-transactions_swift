//
//  ShareSheet.swift
//  transaction
//
//  Created by Lzl on 2026/10/27.
//

import UIKit

enum ShareSheet {
    /// A real JSON file, so AirDrop and Files keep the name.
    static func present(_ text: String) {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(BundleTitle.current).json")
        try? text.write(to: url, atomically: true, encoding: .utf8)
        let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first(where: \.isKeyWindow)?.rootViewController else { return }
        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        top.present(controller, animated: true)
    }
}
