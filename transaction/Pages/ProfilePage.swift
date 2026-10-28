import Combine
import SwiftUI

struct ProfileFormView: View {
    @ObservedObject var store: BookStore
    @Environment(\.pageBack) private var pageBack
    @State private var nickname = ""
    @State private var gender = Gender.secret

    var body: some View {
        let copy = store.copy
        FormPage(title: copy.profileTitle, back: copy.back) {
            FieldLabel(text: copy.nicknameTitle)
            LedgerField(text: $nickname, placeholder: copy.profileHint)
            FieldLabel(text: copy.gender)
            ChoiceRow(labels: Gender.allCases.map { copy.genderName($0) }, index: Gender.allCases.firstIndex(of: gender) ?? 2) { index in
                gender = Gender.allCases[index]
            }
            PillButton(title: copy.save, enabled: !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
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
