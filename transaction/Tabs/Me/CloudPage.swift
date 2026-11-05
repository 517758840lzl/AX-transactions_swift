//
//  CloudPage.swift
//  transaction
//

import SwiftUI
import UIKit

struct CloudPage: View {
    @ObservedObject var store: BookStore
    @State private var busy = false
    @State private var confirmBring = false

    var body: some View {
        let copy = store.copy
        FormPage(title: copy.cloudTitle, back: copy.back, place: "cloud") {
            Text(statusLine(copy))
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
            PillButton(title: copy.cloudSave, enabled: !busy) {
                Task {
                    busy = true
                    let saved = await store.saveToCloud()
                    busy = false
                    store.flash(saved ? copy.cloudSaved : copy.cloudFailed)
                }
            }
            PillButton(title: copy.cloudBring, filled: false, enabled: !busy) {
                confirmBring = true
            }
            if store.cloudOn == false {
                Text(copy.cloudMissing)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                PillButton(title: copy.cloudSettings, filled: false) {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    UIApplication.shared.open(url)
                }
            }
        }
        .alert(copy.cloudBring, isPresented: $confirmBring) {
            Button(copy.cloudBring, role: .destructive) {
                Task {
                    busy = true
                    let brought = await store.bringFromCloud(announce: true)
                    busy = false
                    if !brought { store.flash(copy.cloudFailed) }
                }
            }
            Button(copy.cancel, role: .cancel) {}
        } message: {
            Text(copy.cloudBringAsk)
        }
        .onAppear { store.refreshCloud() }
    }

    private func statusLine(_ copy: LedgerCopy) -> String {
        guard let when = store.cloudWhen else { return copy.cloudNone }
        return copy.cloudWhenLine.replacingOccurrences(of: "{time}", with: store.cloudClock(when))
    }
}
