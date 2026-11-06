//
//  QCShareSheet.swift
//  transaction
//
//  Created by Lzl on 2026/10/27.
//

import UIKit

enum QCShareSheet {
    /// A real JSON file, so AirDrop and Files keep the name.
    static func present(_ text: String) {
        present(data: Data(text.utf8), filename: "\(QCBundleTitle.current).json")
    }

    static func present(data: Data, filename: String) {
        let safe = filename
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent("ledger-export-\(UUID().uuidString)", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let url = folder.appendingPathComponent(safe.isEmpty ? "SpendLogBook.bin" : safe)
            try data.write(to: url, options: .atomic)
            DispatchQueue.main.async {
                show(url)
            }
        } catch {
            return
        }
    }

    private static func show(_ url: URL) {
        let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        guard let host = frontController() else { return }
        if let pop = controller.popoverPresentationController {
            pop.sourceView = host.view
            let bounds = host.view.bounds
            pop.sourceRect = CGRect(x: bounds.midX, y: bounds.midY, width: 1, height: 1)
            pop.permittedArrowDirections = []
        }
        host.present(controller, animated: true)
    }

    private static func frontController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
        let window = scene?.windows.first { $0.isKeyWindow } ?? scene?.windows.first
        guard let root = window?.rootViewController else { return nil }
        var top = root
        while let presented = top.presentedViewController, !presented.isBeingDismissed {
            top = presented
        }
        return top
    }
}
