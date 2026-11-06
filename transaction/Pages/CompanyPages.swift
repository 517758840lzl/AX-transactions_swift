//
//  CompanyPages.swift
//  transaction
//

import SwiftUI

private let companyName = "LIGACAO VITAL - COMERCIO E SERVICOS, (SU), LDA"
private let companyMail = "office@ligacaovital.com"
private let companyRightsPrefix = "© 2026 LIGACAO VITAL - COMERCIO E SERVICOS, (SU), LDA."

struct AboutPage: View {
    var copy: LedgerCopy
    @Environment(\.pageBack) private var pageBack

    var body: some View {
        CompanyFrame(title: copy.about, back: copy.back, onBack: pageBack) {
            PanelCard {
                Text("SpendLogBook")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Palette.ink)
                Text(copy.aboutLead)
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
            }
            CompanyLines(title: copy.aboutDoesTitle, text: copy.aboutDoes)
            CompanyLines(title: copy.aboutNotTitle, text: copy.aboutNot)
            CompanyContact(copy: copy)
        }
    }
}

struct DisclaimerPage: View {
    var copy: LedgerCopy
    @Environment(\.pageBack) private var pageBack

    var body: some View {
        CompanyFrame(title: copy.disclaimer, back: copy.back, onBack: pageBack) {
            PanelCard {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(copy.disclaimerBody.components(separatedBy: "\n"), id: \.self) { line in
                        Text(line)
                            .font(.system(size: 15))
                            .foregroundStyle(Palette.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            CompanyContact(copy: copy)
        }
    }
}

private struct CompanyFrame<Content: View>: View {
    var title: String
    var back: String
    var onBack: () -> Void
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SubpageHead(title: title, back: back, action: onBack)
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.stage)
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    content()
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Palette.stage)
    }
}

private struct CompanyLines: View {
    var title: String
    var text: String

    var body: some View {
        PanelCard {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Palette.ink)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(text.components(separatedBy: "\n"), id: \.self) { line in
                    Text(line)
                        .font(.system(size: 15))
                        .foregroundStyle(Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.top, 10)
        }
    }
}

private struct CompanyContact: View {
    var copy: LedgerCopy

    var body: some View {
        PanelCard {
            Text(copy.aboutOperator)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Palette.muted)
            Text(companyName)
                .font(.system(size: 15))
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
            Text(copy.aboutMail)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Palette.muted)
                .padding(.top, 12)
            Button {
                guard let url = URL(string: "mailto:\(companyMail)") else { return }
                UIApplication.shared.open(url)
            } label: {
                Text(companyMail)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Palette.ink)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
            Text(copy.aboutWrite)
                .font(.system(size: 13))
                .foregroundStyle(Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 12)
            Text("\(companyRightsPrefix) \(copy.rightsReserved)")
                .font(.system(size: 13))
                .foregroundStyle(Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
        }
    }
}
