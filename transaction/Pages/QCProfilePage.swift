//
//  QCProfilePage.swift
//  transaction
//
//  Created by Lzl on 2026/10/26.
//

import SwiftUI

struct QCProfileFormView: View {
    @ObservedObject var store: QCBookStore
    @Environment(\.pageBack) private var pageBack
    @State private var nickname = ""
    @State private var gender = QCGender.secret

    var body: some View {
        let copy = store.copy
        QCFormPage(title: copy.profileTitle, back: copy.back, place: "profile") {
            QCFieldLabel(text: copy.avatarTitle)
            QCAvatarMark(gender: gender, size: 72)
            QCFieldLabel(text: copy.nicknameTitle)
            QCLedgerField(text: $nickname, placeholder: copy.profileHint)
            QCFieldLabel(text: copy.gender)
            QCChoiceRow(labels: QCGender.allCases.map { copy.genderName($0) }, index: QCGender.allCases.firstIndex(of: gender) ?? 2) { index in
                gender = QCGender.allCases[index]
            }
            QCPillButton(title: copy.save, enabled: !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                store.saveProfile(nickname: nickname, gender: gender)
                pageBack()
            }
        }
        .onAppear {
            nickname = store.book.nickname
            gender = store.book.gender
        }
    }
}
