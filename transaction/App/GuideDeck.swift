//
//  GuideDeck.swift
//  transaction
//

import SwiftUI

/// Three first-launch pages. Skip on any page, or finish on the last one, and it does not return.
struct GuideDeck: View {
    var onFinish: () -> Void
    @State private var page = 0

    var body: some View {
        let copy = GuideWords.current
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(copy.skip, action: onFinish)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Palette.muted)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
            }
            TabView(selection: $page) {
                ForEach(Array(copy.leaves.enumerated()), id: \.offset) { index, leaf in
                    GuideLeafView(leaf: leaf)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            HStack(spacing: 8) {
                ForEach(copy.leaves.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == page ? Palette.ink : Palette.line)
                        .frame(width: index == page ? 18 : 7, height: 7)
                }
            }
            .padding(.top, 8)
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.stage.ignoresSafeArea())
    }

    static let seenKey = "guideSeen"

    static var alreadySeen: Bool {
        UserDefaults.standard.bool(forKey: seenKey)
    }

    static func markSeen() {
        UserDefaults.standard.set(true, forKey: seenKey)
    }
}

private struct GuideLeaf {
    var title: String
    var body: String
    var points: [String]
    var scene: Int
}

private struct GuideLeafView: View {
    var leaf: GuideLeaf

    var body: some View {
        VStack(spacing: 0) {
            GuidePoster(scene: leaf.scene)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Text(leaf.title)
                .font(.system(size: 32, weight: .bold))
                .tracking(-0.5)
                .foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 32)
            Text(leaf.body)
                .font(.system(size: 17))
                .foregroundStyle(Palette.muted)
                .lineSpacing(5)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 36)
                .padding(.top, 12)
                .padding(.bottom, 8)
        }
    }
}

/// Full-bleed pictures. They are scenes, not screens of the app.
private struct GuidePoster: View {
    var scene: Int

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                posterGround
                switch scene {
                case 0: dawn(w, h)
                case 1: moon(w, h)
                default: papers(w, h)
                }
            }
            .frame(width: w, height: h)
        }
    }

    private var posterGround: some View {
        LinearGradient(
            colors: ground,
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var ground: [Color] {
        switch scene {
        case 0: return [Color(red: 1, green: 0.90, blue: 0.90), Palette.stage]
        case 1: return [Color(red: 1, green: 0.96, blue: 0.90), Palette.stage]
        default: return [Color(red: 0.95, green: 0.93, blue: 0.98), Palette.stage]
        }
    }

    private func dawn(_ w: CGFloat, _ h: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(Color(red: 1, green: 0.72, blue: 0.68))
                .frame(width: w * 0.78)
                .offset(x: w * 0.16, y: -h * 0.16)
            Circle()
                .fill(Color.white.opacity(0.55))
                .frame(width: w * 0.34)
                .offset(x: w * 0.28, y: -h * 0.28)
            Ellipse()
                .fill(Color.white.opacity(0.45))
                .frame(width: w * 0.86, height: h * 0.16)
                .offset(y: h * 0.30)
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white)
                .frame(width: w * 0.42, height: h * 0.46)
                .shadow(color: Palette.ink.opacity(0.08), radius: 16, y: 10)
                .rotationEffect(.degrees(-11))
                .offset(x: -w * 0.12, y: h * 0.02)
            cup
                .offset(x: w * 0.24, y: h * 0.12)
            sprout
                .offset(x: -w * 0.30, y: h * 0.16)
        }
    }

    private var cup: some View {
        VStack(spacing: 0) {
            Ellipse()
                .fill(Color(red: 0.98, green: 0.86, blue: 0.78))
                .frame(width: 54, height: 16)
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white)
                .frame(width: 58, height: 48)
                .overlay(alignment: .trailing) {
                    Capsule()
                        .stroke(Palette.ink.opacity(0.18), lineWidth: 3)
                        .frame(width: 16, height: 22)
                        .offset(x: 10)
                }
        }
    }

    private var sprout: some View {
        ZStack {
            Capsule()
                .fill(Color(red: 0.55, green: 0.72, blue: 0.52))
                .frame(width: 6, height: 46)
                .offset(y: 8)
            Ellipse()
                .fill(Color(red: 0.62, green: 0.78, blue: 0.55))
                .frame(width: 28, height: 16)
                .rotationEffect(.degrees(-28))
                .offset(x: -12, y: -8)
            Ellipse()
                .fill(Color(red: 0.45, green: 0.68, blue: 0.48))
                .frame(width: 26, height: 15)
                .rotationEffect(.degrees(24))
                .offset(x: 12, y: -4)
        }
    }

    private func moon(_ w: CGFloat, _ h: CGFloat) -> some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: w * 0.72)
                .shadow(color: Palette.ink.opacity(0.06), radius: 18, y: 8)
                .offset(y: -h * 0.06)
            Circle()
                .fill(Color(red: 1, green: 0.96, blue: 0.90))
                .frame(width: w * 0.58)
                .offset(x: w * 0.16, y: -h * 0.10)
            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .fill(Color.white)
                    .frame(width: index == 2 ? 18 : 8)
                    .offset(x: CGFloat(index - 2) * w * 0.16, y: -h * 0.34)
            }
            HStack(alignment: .bottom, spacing: w * 0.04) {
                pebble(28)
                pebble(18)
                pebble(40)
                pebble(22)
                pebble(32)
            }
            .offset(y: h * 0.28)
        }
    }

    private func pebble(_ side: CGFloat) -> some View {
        Ellipse()
            .fill(Color.white)
            .frame(width: side, height: side * 0.72)
            .shadow(color: Palette.ink.opacity(0.05), radius: 4, y: 3)
    }

    private func papers(_ w: CGFloat, _ h: CGFloat) -> some View {
        ZStack {
            sheet(width: w * 0.46, height: h * 0.42, turn: -16, fill: Color.white)
                .offset(x: -w * 0.16, y: h * 0.04)
            sheet(width: w * 0.40, height: h * 0.36, turn: 12, fill: Palette.wash)
                .offset(x: w * 0.18, y: -h * 0.08)
            sheet(width: w * 0.34, height: h * 0.30, turn: -4, fill: Color.white)
                .offset(x: w * 0.02, y: h * 0.16)
            star
                .offset(x: w * 0.30, y: -h * 0.28)
        }
    }

    private func sheet(width: CGFloat, height: CGFloat, turn: Double, fill: Color) -> some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(fill)
            .frame(width: width, height: height)
            .shadow(color: Palette.ink.opacity(0.07), radius: 14, y: 8)
            .rotationEffect(.degrees(turn))
    }

    private var star: some View {
        Canvas { context, size in
            var path = Path()
            let cx = size.width / 2
            let cy = size.height / 2
            let tips: [(CGFloat, CGFloat)] = [
                (0, -1), (0.22, -0.28), (1, -0.22), (0.36, 0.18),
                (0.55, 1), (0, 0.42), (-0.55, 1), (-0.36, 0.18),
                (-1, -0.22), (-0.22, -0.28)
            ]
            for (index, tip) in tips.enumerated() {
                let point = CGPoint(x: cx + tip.0 * cx * 0.86, y: cy + tip.1 * cy * 0.86)
                if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            path.closeSubpath()
            context.fill(path, with: .color(Palette.pink))
        }
        .frame(width: 36, height: 36)
    }
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
                        title: "从一笔记账开始",
                        body: "生活里的进出，写成自己的一笔。记在这台手机上，就够了。",
                        points: ["支出和收入", "账户转账", "分类可加"],
                        scene: 0
                    ),
                    GuideLeaf(
                        title: "这个月看得清楚",
                        body: "一个月过去，花出去的和留下来的，翻开就能看见。",
                        points: ["月收支", "日历", "未核对"],
                        scene: 1
                    ),
                    GuideLeaf(
                        title: "想法留在账旁边",
                        body: "数字旁边，也可以留一句今天。这些字只在你自己这里。",
                        points: ["四种记录", "只在本机", "可存 iCloud"],
                        scene: 2
                    ),
                ]
            )
        case .zhHant:
            return GuideWords(
                skip: "跳過", next: "下一頁", start: "開始使用",
                leaves: [
                    GuideLeaf(title: "從一筆記帳開始", body: "生活裡的進出，寫成自己的一筆。記在這台手機上，就夠了。", points: ["支出和收入", "帳戶轉帳", "分類可加"], scene: 0),
                    GuideLeaf(title: "這個月看得清楚", body: "一個月過去，花出去的和留下來的，翻開就能看見。", points: ["月收支", "日曆", "未核對"], scene: 1),
                    GuideLeaf(title: "想法留在帳旁邊", body: "數字旁邊，也可以留一句今天。這些字只在你自己這裡。", points: ["四種記錄", "只在本機", "可存 iCloud"], scene: 2),
                ]
            )
        case .ja:
            return GuideWords(
                skip: "スキップ", next: "次へ", start: "はじめる",
                leaves: [
                    GuideLeaf(title: "まず一件を書く", body: "日々の出入りを、自分の一言として残す。この端末に書いてあれば、それで足ります。", points: ["支出と収入", "口座の振替", "分類を追加"], scene: 0),
                    GuideLeaf(title: "今月が一目でわかる", body: "ひと月が過ぎたら、出ていったものと残ったものが、開けば見えます。", points: ["月の収支", "カレンダー", "未確認"], scene: 1),
                    GuideLeaf(title: "思いつきは帳簿のそばに", body: "数字のそばに、今日の一文を置ける。その言葉は、あなただけのところにあります。", points: ["四つの記録", "端末の中だけ", "iCloud"], scene: 2),
                ]
            )
        case .ko:
            return GuideWords(
                skip: "건너뛰기", next: "다음", start: "시작하기",
                leaves: [
                    GuideLeaf(title: "한 건부터 적기", body: "하루의 들어오고 나감을 내 기록으로 남깁니다. 이 휴대폰에 적혀 있으면 충분합니다.", points: ["지출과 수입", "계좌 이체", "분류 추가"], scene: 0),
                    GuideLeaf(title: "이번 달이 한눈에", body: "한 달이 지나면, 나간 것과 남은 것이 펼치면 보입니다.", points: ["월 수지", "달력", "미확인"], scene: 1),
                    GuideLeaf(title: "생각은 장부 옆에", body: "숫자 옆에 오늘의 한 줄을 둘 수 있습니다. 그 글은 당신만의 자리에 있습니다.", points: ["네 가지 기록", "기기 안에만", "iCloud"], scene: 2),
                ]
            )
        case .es:
            return GuideWords(
                skip: "Omitir", next: "Siguiente", start: "Empezar",
                leaves: [
                    GuideLeaf(title: "Empieza por un apunte", body: "Lo que entra y lo que sale se queda como algo tuyo. Con tenerlo en este teléfono, basta.", points: ["Gasto e ingreso", "Traspaso", "Nuevas categorías"], scene: 0),
                    GuideLeaf(title: "El mes, de un vistazo", body: "Cuando pasa un mes, lo que se fue y lo que quedó se ve al abrir.", points: ["Mes", "Calendario", "Sin revisar"], scene: 1),
                    GuideLeaf(title: "Las ideas, junto a las cuentas", body: "Junto a los números cabe una frase de hoy. Esas palabras se quedan contigo.", points: ["Cuatro tipos", "Solo en el dispositivo", "iCloud"], scene: 2),
                ]
            )
        case .pt:
            return GuideWords(
                skip: "Ignorar", next: "Seguinte", start: "Começar",
                leaves: [
                    GuideLeaf(title: "Começa por um lançamento", body: "O que entra e o que sai fica como coisa tua. Estar neste telemóvel chega.", points: ["Despesa e receita", "Transferência", "Novas categorias"], scene: 0),
                    GuideLeaf(title: "O mês, num olhar", body: "Passado um mês, o que saiu e o que ficou vê-se ao abrir.", points: ["Mês", "Calendário", "Por rever"], scene: 1),
                    GuideLeaf(title: "As ideias, ao lado das contas", body: "Ao lado dos números cabe uma frase de hoje. Essas palavras ficam contigo.", points: ["Quatro tipos", "Só no dispositivo", "iCloud"], scene: 2),
                ]
            )
        case .fr:
            return GuideWords(
                skip: "Passer", next: "Suivant", start: "Commencer",
                leaves: [
                    GuideLeaf(title: "Commence par une écriture", body: "Ce qui entre et ce qui sort devient une note à toi. L'avoir sur ce téléphone suffit.", points: ["Dépense et recette", "Virement", "Catégories"], scene: 0),
                    GuideLeaf(title: "Le mois d'un coup d'œil", body: "Le mois passé, ce qui est parti et ce qui reste se voit en ouvrant.", points: ["Mois", "Calendrier", "À vérifier"], scene: 1),
                    GuideLeaf(title: "Les idées, à côté des comptes", body: "À côté des chiffres, une phrase d'aujourd'hui a sa place. Ces mots restent avec toi.", points: ["Quatre formes", "Sur l'appareil", "iCloud"], scene: 2),
                ]
            )
        case .de:
            return GuideWords(
                skip: "Überspringen", next: "Weiter", start: "Loslegen",
                leaves: [
                    GuideLeaf(title: "Beginne mit einer Buchung", body: "Was reingeht und rausgeht, wird zu deiner eigenen Notiz. Auf diesem Telefon zu sein, reicht.", points: ["Ausgabe und Einnahme", "Umbuchung", "Kategorien"], scene: 0),
                    GuideLeaf(title: "Der Monat auf einen Blick", body: "Ist ein Monat vorbei, sieht man beim Aufschlagen, was wegging und was blieb.", points: ["Monat", "Kalender", "Offen"], scene: 1),
                    GuideLeaf(title: "Einfälle neben den Konten", body: "Neben den Zahlen hat ein Satz von heute Platz. Diese Worte bleiben bei dir.", points: ["Vier Arten", "Nur auf dem Gerät", "iCloud"], scene: 2),
                ]
            )
        case .it:
            return GuideWords(
                skip: "Salta", next: "Avanti", start: "Inizia",
                leaves: [
                    GuideLeaf(title: "Parti da una voce", body: "Quello che entra e quello che esce diventa una nota tua. Tenerlo su questo telefono basta.", points: ["Uscita ed entrata", "Giroconto", "Categorie"], scene: 0),
                    GuideLeaf(title: "Il mese, a colpo d'occhio", body: "Passato un mese, ciò che è uscito e ciò che è rimasto si vede aprendo.", points: ["Mese", "Calendario", "Da controllare"], scene: 1),
                    GuideLeaf(title: "Le idee, accanto ai conti", body: "Accanto ai numeri c'è posto per una frase di oggi. Quelle parole restano con te.", points: ["Quattro tipi", "Solo sul dispositivo", "iCloud"], scene: 2),
                ]
            )
        case .en:
            return GuideWords(
                skip: "Skip", next: "Next", start: "Get started",
                leaves: [
                    GuideLeaf(
                        title: "Start with one entry",
                        body: "What comes in and what goes out becomes a note of your own. Keeping it on this phone is enough.",
                        points: ["Spending and income", "Transfers", "Your categories"],
                        scene: 0
                    ),
                    GuideLeaf(
                        title: "See the month clearly",
                        body: "When a month has passed, what left and what stayed is there when you open it.",
                        points: ["This month", "Calendar", "Unchecked"],
                        scene: 1
                    ),
                    GuideLeaf(
                        title: "Keep ideas beside the book",
                        body: "Next to the numbers, there is room for one line about today. Those words stay with you.",
                        points: ["Four kinds", "On this device", "iCloud"],
                        scene: 2
                    ),
                ]
            )
        }
    }
}
