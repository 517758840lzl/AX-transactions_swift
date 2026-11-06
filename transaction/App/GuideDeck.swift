//
//  GuideDeck.swift
//  transaction
//

import SwiftUI
import UIKit

/// Three first-launch pages. Skip on any page, or finish on the last one, and it does not return.
struct GuideDeck: View {
    var onFinish: () -> Void
    @State private var page = 0

    var body: some View {
        let copy = GuideWords.current
        let leaf = copy.leaves[min(max(page, 0), copy.leaves.count - 1)]
        ZStack {
            GuideWash(scene: leaf.scene)
                .ignoresSafeArea()
            GeometryReader { geo in
                TabView(selection: $page) {
                    ForEach(Array(copy.leaves.enumerated()), id: \.offset) { index, item in
                        ZStack {
                            GuideWash(scene: item.scene)
                            Image(Self.assetName(item.scene))
                                .resizable()
                                .scaledToFit()
                                .frame(width: geo.size.width, height: geo.size.height)
                        }
                        .frame(width: geo.size.width, height: geo.size.height)
                        .ignoresSafeArea()
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .background(WashBackdrop())
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(copy.skip, action: onFinish)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Palette.muted)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 10)
                }
                Spacer()
                    .allowsHitTesting(false)
                VStack(spacing: 0) {
                    Text(leaf.body)
                        .font(.system(size: 18, weight: .regular))
                        .foregroundStyle(Palette.muted)
                        .lineSpacing(6)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 40)
                    HStack(spacing: 8) {
                        ForEach(copy.leaves.indices, id: \.self) { index in
                            Capsule()
                                .fill(index == page ? Palette.ink : Palette.line)
                                .frame(width: index == page ? 18 : 7, height: 7)
                        }
                    }
                    .padding(.top, 22)
                    .animation(.easeOut(duration: 0.2), value: page)
                    PillButton(title: page == copy.leaves.count - 1 ? copy.start : copy.next) {
                        if page < copy.leaves.count - 1 {
                            withAnimation(.easeOut(duration: 0.25)) { page += 1 }
                        } else {
                            onFinish()
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 18)
                    .padding(.bottom, 12)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(GuideWash(scene: leaf.scene).ignoresSafeArea())
    }

    private static func assetName(_ scene: Int) -> String {
        switch scene {
        case 0: return "GuideFlow"
        case 1: return "GuideMonth"
        default: return "GuideAside"
        }
    }

    static let seenKey = "guideSeen"

    static var alreadySeen: Bool {
        UserDefaults.standard.bool(forKey: seenKey)
    }

    static func markSeen() {
        UserDefaults.standard.set(true, forKey: seenKey)
    }
}

/// Clears the page controller's own white fill so the wash can reach the status bar and the home edge.
private struct WashBackdrop: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear
        return view
    }

    func updateUIView(_ view: UIView, context: Context) {
        DispatchQueue.main.async {
            view.superview?.backgroundColor = .clear
            view.superview?.superview?.backgroundColor = .clear
        }
    }
}

/// Full-page color. A soft light sits in the blush, then the same hue eases down.
private struct GuideWash: View {
    var scene: Int

    var body: some View {
        ZStack {
            LinearGradient(colors: fall, startPoint: .top, endPoint: .bottom)
            RadialGradient(colors: [glow, glow.opacity(0)], center: light, startRadius: 10, endRadius: 340)
            RadialGradient(colors: [Color.white.opacity(0.55), Color.white.opacity(0)], center: lift, startRadius: 8, endRadius: 220)
        }
    }

    private var fall: [Color] {
        switch scene {
        case 0:
            return [
                Color(red: 1, green: 0.75, blue: 0.82),
                Color(red: 1, green: 0.88, blue: 0.91),
                Color(red: 1, green: 0.96, blue: 0.97)
            ]
        case 1:
            return [
                Color(red: 1, green: 0.76, blue: 0.83),
                Color(red: 1, green: 0.89, blue: 0.92),
                Color(red: 1, green: 0.96, blue: 0.97)
            ]
        default:
            return [
                Color(red: 1, green: 0.76, blue: 0.84),
                Color(red: 1, green: 0.89, blue: 0.93),
                Color(red: 0.99, green: 0.96, blue: 0.97)
            ]
        }
    }

    private var glow: Color {
        switch scene {
        case 0: return Color(red: 1, green: 0.70, blue: 0.78)
        case 1: return Color(red: 1, green: 0.71, blue: 0.80)
        default: return Color(red: 1, green: 0.72, blue: 0.82)
        }
    }

    private var light: UnitPoint {
        switch scene {
        case 0: return UnitPoint(x: 0.78, y: 0.18)
        case 1: return UnitPoint(x: 0.22, y: 0.16)
        default: return UnitPoint(x: 0.55, y: 0.22)
        }
    }

    private var lift: UnitPoint {
        switch scene {
        case 0: return UnitPoint(x: 0.28, y: 0.42)
        case 1: return UnitPoint(x: 0.72, y: 0.38)
        default: return UnitPoint(x: 0.34, y: 0.46)
        }
    }
}

private struct GuideLeaf {
    var title: String
    var body: String
    var points: [String]
    var scene: Int
}

private struct GuideWords {
    var skip: String
    var next: String
    var start: String
    var leaves: [GuideLeaf]

    static var current: GuideWords {
        words(for: deviceLocale)
    }

    private static var deviceLocale: BookLocale {
        let code = Locale.preferredLanguages.first ?? "en"
        if code.hasPrefix("zh-Hant") || code.contains("Hant") || code.hasPrefix("zh-TW") || code.hasPrefix("zh-HK") {
            return .zhHant
        }
        if code.hasPrefix("zh") { return .zh }
        let head = String(code.prefix(2))
        return BookLocale(rawValue: head) ?? .en
    }

    private static func words(for locale: BookLocale) -> GuideWords {
        switch locale {
        case .zh:
            return GuideWords(
                skip: "跳过", next: "下一页", start: "开始使用",
                leaves: [
                    GuideLeaf(
                        title: "进出都记一笔",
                        body: "花出去的和收进来的，都记在这台手机上。",
                        points: ["支出和收入", "账户转账", "分类可加"],
                        scene: 0
                    ),
                    GuideLeaf(
                        title: "这个月花在哪",
                        body: "这个月的钱去了哪里，翻开就能看见。",
                        points: ["月收支", "分类", "账户"],
                        scene: 1
                    ),
                    GuideLeaf(
                        title: "账旁边留一句",
                        body: "数字旁边，也可以留一句今天。",
                        points: ["四种记录", "只在本机", "可存 iCloud"],
                        scene: 2
                    ),
                ]
            )
        case .zhHant:
            return GuideWords(
                skip: "跳過", next: "下一頁", start: "開始使用",
                leaves: [
                    GuideLeaf(title: "進出都記一筆", body: "花出去的和收進來的，都記在這台手機上。", points: ["支出和收入", "帳戶轉帳", "分類可加"], scene: 0),
                    GuideLeaf(title: "這個月花在哪", body: "這個月的錢去了哪裡，翻開就能看見。", points: ["月收支", "分類", "帳戶"], scene: 1),
                    GuideLeaf(title: "帳旁邊留一句", body: "數字旁邊，也可以留一句今天。", points: ["四種記錄", "只在本機", "可存 iCloud"], scene: 2),
                ]
            )
        case .ja:
            return GuideWords(
                skip: "スキップ", next: "次へ", start: "はじめる",
                leaves: [
                    GuideLeaf(title: "出入りを一件ずつ", body: "出ていったお金も、入ってきたお金も、この端末に残します。", points: ["支出と収入", "口座の振替", "分類を追加"], scene: 0),
                    GuideLeaf(title: "今月はどこに使ったか", body: "今月のお金が向かった先は、開けば見えます。", points: ["月の収支", "分類", "口座"], scene: 1),
                    GuideLeaf(title: "帳簿のそばに一文", body: "数字のそばに、今日の一文を置けます。", points: ["四つの記録", "端末の中だけ", "iCloud"], scene: 2),
                ]
            )
        case .ko:
            return GuideWords(
                skip: "건너뛰기", next: "다음", start: "시작하기",
                leaves: [
                    GuideLeaf(title: "들어오고 나감을 한 건씩", body: "나간 돈과 들어온 돈, 이 휴대폰에 남겨 둡니다.", points: ["지출과 수입", "계좌 이체", "분류 추가"], scene: 0),
                    GuideLeaf(title: "이번 달은 어디에 썼나", body: "이번 달 돈이 간 곳은, 펼치면 보입니다.", points: ["월 수지", "분류", "계좌"], scene: 1),
                    GuideLeaf(title: "장부 옆에 한 줄", body: "숫자 옆에, 오늘의 한 줄을 둘 수 있습니다.", points: ["네 가지 기록", "기기 안에만", "iCloud"], scene: 2),
                ]
            )
        case .es:
            return GuideWords(
                skip: "Omitir", next: "Siguiente", start: "Empezar",
                leaves: [
                    GuideLeaf(title: "Cada entrada y cada salida", body: "Lo que se gasta y lo que entra se queda en este teléfono.", points: ["Gasto e ingreso", "Traspaso", "Nuevas categorías"], scene: 0),
                    GuideLeaf(title: "Dónde se fue este mes", body: "A dónde fue el dinero este mes se ve al abrir.", points: ["Mes", "Categorías", "Cuentas"], scene: 1),
                    GuideLeaf(title: "Una frase junto a las cuentas", body: "Junto a los números cabe una frase de hoy.", points: ["Cuatro tipos", "Solo en el dispositivo", "iCloud"], scene: 2),
                ]
            )
        case .pt:
            return GuideWords(
                skip: "Ignorar", next: "Seguinte", start: "Começar",
                leaves: [
                    GuideLeaf(title: "Cada entrada e cada saída", body: "O que se gasta e o que entra fica neste telemóvel.", points: ["Despesa e receita", "Transferência", "Novas categorias"], scene: 0),
                    GuideLeaf(title: "Para onde foi este mês", body: "Para onde foi o dinheiro este mês vê-se ao abrir.", points: ["Mês", "Categorias", "Contas"], scene: 1),
                    GuideLeaf(title: "Uma frase ao lado das contas", body: "Ao lado dos números cabe uma frase de hoje.", points: ["Quatro tipos", "Só no dispositivo", "iCloud"], scene: 2),
                ]
            )
        case .fr:
            return GuideWords(
                skip: "Passer", next: "Suivant", start: "Commencer",
                leaves: [
                    GuideLeaf(title: "Chaque entrée, chaque sortie", body: "Ce qui part et ce qui rentre reste sur ce téléphone.", points: ["Dépense et recette", "Virement", "Catégories"], scene: 0),
                    GuideLeaf(title: "Où est passé ce mois", body: "Où est allé l'argent ce mois-ci se voit en ouvrant.", points: ["Mois", "Catégories", "Comptes"], scene: 1),
                    GuideLeaf(title: "Une phrase à côté des comptes", body: "À côté des chiffres, une phrase d'aujourd'hui a sa place.", points: ["Quatre formes", "Sur l'appareil", "iCloud"], scene: 2),
                ]
            )
        case .de:
            return GuideWords(
                skip: "Überspringen", next: "Weiter", start: "Loslegen",
                leaves: [
                    GuideLeaf(title: "Jede Ausgabe, jede Einnahme", body: "Was rausgeht und was reinkommt, bleibt auf diesem Telefon.", points: ["Ausgabe und Einnahme", "Umbuchung", "Kategorien"], scene: 0),
                    GuideLeaf(title: "Wohin das Geld diesen Monat ging", body: "Wohin das Geld diesen Monat ging, sieht man beim Öffnen.", points: ["Monat", "Kategorien", "Konten"], scene: 1),
                    GuideLeaf(title: "Ein Satz neben den Zahlen", body: "Neben den Zahlen hat ein Satz von heute Platz.", points: ["Vier Arten", "Nur auf dem Gerät", "iCloud"], scene: 2),
                ]
            )
        case .it:
            return GuideWords(
                skip: "Salta", next: "Avanti", start: "Inizia",
                leaves: [
                    GuideLeaf(title: "Ogni uscita, ogni entrata", body: "Ciò che esce e ciò che entra resta su questo telefono.", points: ["Uscita ed entrata", "Giroconto", "Categorie"], scene: 0),
                    GuideLeaf(title: "Dove sono finiti i soldi", body: "Dove è andato il denaro questo mese si vede aprendo.", points: ["Mese", "Categorie", "Conti"], scene: 1),
                    GuideLeaf(title: "Una frase accanto ai conti", body: "Accanto ai numeri c'è posto per una frase di oggi.", points: ["Quattro tipi", "Solo sul dispositivo", "iCloud"], scene: 2),
                ]
            )
        case .en:
            return GuideWords(
                skip: "Skip", next: "Next", start: "Get started",
                leaves: [
                    GuideLeaf(
                        title: "Money in, money out",
                        body: "What you spend and what comes in stays on this phone.",
                        points: ["Spending and income", "Transfers", "Your categories"],
                        scene: 0
                    ),
                    GuideLeaf(
                        title: "Where this month went",
                        body: "Where the money went this month is there when you open it.",
                        points: ["This month", "Categories", "Accounts"],
                        scene: 1
                    ),
                    GuideLeaf(
                        title: "One line beside the numbers",
                        body: "Next to the numbers, there is room for one line about today.",
                        points: ["Four kinds", "On this device", "iCloud"],
                        scene: 2
                    ),
                ]
            )
        }
    }
}
