//
//  QCCompanyPages.swift
//  transaction
//

//  Created by Lzl on 2026/10/26.
//

import SwiftUI

private let companyName = "LIGACAO VITAL - COMERCIO E SERVICOS, (SU), LDA"
private let companyMail = "office@ligacaovital.com"
private let companyRights = "© 2026 LIGACAO VITAL - COMERCIO E SERVICOS, (SU), LDA. All rights reserved."

struct QCAboutPage: View {
    var copy: QCLedgerCopy
    @Environment(\.pageBack) private var pageBack

    var body: some View {
        QCCompanyFrame(title: copy.about, back: copy.back, onBack: pageBack) {
            QCPanelCard {
                VStack(alignment: .leading, spacing: 18) {
                    Text("SpendLogBook")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(QCPalette.ink)
                    QCCompanyNote(text: copy.aboutLead, fill: QCPalette.neutral)
                    aboutDoes(copy)
                    aboutLimits(copy)
                    QCCompanyContact(copy: copy)
                }
            }
        }
    }
}

struct QCDisclaimerPage: View {
    var copy: QCLedgerCopy
    @Environment(\.pageBack) private var pageBack

    var body: some View {
        QCCompanyFrame(title: copy.disclaimer, back: copy.back, onBack: pageBack) {
            QCPanelCard {
                VStack(alignment: .leading, spacing: 14) {
                    let lines = copy.disclaimerBody.components(separatedBy: "\n")
                    ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                        disclaimerLine(line, index: index, count: lines.count)
                    }
                    QCCompanyContact(copy: copy)
                        .padding(.top, 4)
                }
            }
        }
    }
}

private struct QCCompanyFrame<Content: View>: View {
    var title: String
    var back: String
    var onBack: () -> Void
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            QCSubpageHead(title: title, back: back, action: onBack)
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(QCPalette.stage)
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    content()
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(QCPalette.stage)
    }
}

private struct QCCompanyNote: View {
    var text: String
    var ink: Color = QCPalette.ink
    var fill: Color

    var body: some View {
        Text(text)
            .font(.system(size: 15))
            .foregroundStyle(ink)
            .fixedSize(horizontal: false, vertical: true)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(fill, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private func companyTitle(_ title: String) -> some View {
    Text(title)
        .font(.system(size: 15, weight: .bold))
        .foregroundStyle(QCPalette.ink)
}

private func companyLine(_ text: String, ink: Color = QCPalette.ink) -> some View {
    Text(text)
        .font(.system(size: 15))
        .foregroundStyle(ink)
        .fixedSize(horizontal: false, vertical: true)
}

private func aboutDoes(_ copy: QCLedgerCopy) -> some View {
    let lines = copy.aboutDoes.components(separatedBy: "\n")
    return VStack(alignment: .leading, spacing: 8) {
        companyTitle(copy.aboutDoesTitle)
        ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
            if index == lines.count - 1 {
                QCCompanyNote(text: line, fill: QCPalette.wash)
            } else {
                companyLine(line)
            }
        }
    }
}

private func aboutLimits(_ copy: QCLedgerCopy) -> some View {
    VStack(alignment: .leading, spacing: 8) {
        companyTitle(copy.aboutNotTitle)
        VStack(alignment: .leading, spacing: 8) {
            ForEach(copy.aboutNot.components(separatedBy: "\n"), id: \.self) { line in
                companyLine(line, ink: QCPalette.down)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(QCPalette.wash, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

@ViewBuilder
private func disclaimerLine(_ line: String, index: Int, count: Int) -> some View {
    if index == 0 {
        QCCompanyNote(text: line, ink: QCPalette.down, fill: QCPalette.wash)
    } else if count > 2 && index == count - 2 {
        QCCompanyNote(text: line, fill: QCPalette.neutral)
    } else if index == count - 1 {
        companyLine(line, ink: QCPalette.muted)
    } else {
        companyLine(line)
    }
}

private struct QCCompanyContact: View {
    var copy: QCLedgerCopy

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(copy.aboutOperator)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(QCPalette.muted)
            Text(companyName)
                .font(.system(size: 15))
                .foregroundStyle(QCPalette.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
            Text(copy.aboutMail)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(QCPalette.muted)
                .padding(.top, 12)
            Button {
                guard let url = URL(string: "mailto:\(companyMail)") else { return }
                UIApplication.shared.open(url)
            } label: {
                Text(companyMail)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(QCPalette.ink)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
            Text(copy.aboutWrite)
                .font(.system(size: 13))
                .foregroundStyle(QCPalette.muted)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 12)
            Text(companyRights)
                .font(.system(size: 13))
                .foregroundStyle(QCPalette.muted)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
        }
    }
}
