//
//  QCPrivacyWebView.swift
//  transaction
//
//  Created by Lzl on 2026/10/26.
//

import SwiftUI
import WebKit

struct QCPrivacyWeb: UIViewRepresentable {
    var url: URL

    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView()
        view.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        return view
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}
