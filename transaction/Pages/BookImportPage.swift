import Combine
import SwiftUI
import UniformTypeIdentifiers

struct ImportView: View {
    @ObservedObject var store: BookStore
    @Environment(\.pageBack) private var pageBack
    @State private var text = ""
    @State private var message = ""
    @State private var picking = false

    var body: some View {
        let copy = store.copy
        FormPage(title: copy.importData, back: copy.back) {
            TextEditor(text: $text)
                .frame(minHeight: 180)
                .padding(8)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Palette.line, lineWidth: 1))
                .overlay(alignment: .topLeading) {
                    if text.isEmpty {
                        Text(copy.importPaste).foregroundStyle(Palette.faint).padding(14)
                    }
                }
            PillButton(title: copy.importFile, filled: false) { picking = true }
            PillButton(title: copy.importData, enabled: !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                if store.importDocument(text) {
                    message = copy.importDone
                    store.flash(copy.importDone)
                    pageBack()
                } else {
                    message = copy.importInvalid
                }
            }
            if !message.isEmpty {
                Text(message).font(.system(size: 13, weight: .semibold)).foregroundStyle(Palette.muted)
            }
        }
        .fileImporter(isPresented: $picking, allowedContentTypes: [.json, .plainText]) { result in
            if case .success(let url) = result, url.startAccessingSecurityScopedResource() {
                defer { url.stopAccessingSecurityScopedResource() }
                text = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
            }
        }
    }
}
