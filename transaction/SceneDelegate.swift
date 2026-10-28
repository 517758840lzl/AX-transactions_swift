//
//  SceneDelegate.swift
//  transaction
//
//  Created by Lzl on 2026/9/28.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        UIScrollView.appearance().delaysContentTouches = false
        UIScrollView.appearance().canCancelContentTouches = true
        UIScrollView.appearance().keyboardDismissMode = .onDrag
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIHostingController(rootView: RootView(store: BookStore.open()))
        window.overrideUserInterfaceStyle = .light
        self.window = window
        window.makeKeyAndVisible()
    }
}
