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
                Text("SpendLogBook")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(QCPalette.ink)
                Text(copy.aboutLead)
                    .font(.system(size: 15))
                    .foregroundStyle(QCPalette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
            }
            QCCompanyLines(title: copy.aboutDoesTitle, text: copy.aboutDoes)
            QCCompanyLines(title: copy.aboutNotTitle, text: copy.aboutNot)
            QCCompanyContact(copy: copy)
        }
    }
}

struct QCDisclaimerPage: View {
    var copy: QCLedgerCopy
    @Environment(\.pageBack) private var pageBack

    var body: some View {
        QCCompanyFrame(title: copy.disclaimer, back: copy.back, onBack: pageBack) {
            QCPanelCard {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(copy.disclaimerBody.components(separatedBy: "\n"), id: \.self) { line in
                        Text(line)
                            .font(.system(size: 15))
                            .foregroundStyle(QCPalette.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            QCCompanyContact(copy: copy)
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

private struct QCCompanyLines: View {
    var title: String
    var text: String

    var body: some View {
        QCPanelCard {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(QCPalette.ink)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(text.components(separatedBy: "\n"), id: \.self) { line in
                    Text(line)
                        .font(.system(size: 15))
                        .foregroundStyle(QCPalette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.top, 10)
        }
    }
}

private struct QCCompanyContact: View {
    var copy: QCLedgerCopy

    var body: some View {
        QCPanelCard {
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
