//
//  QCSparkPage.swift
//  transaction
//

import Combine
import PhotosUI
import SwiftUI
import UIKit

struct QCSparkHomeView: View {
    @ObservedObject var store: QCBookStore
    @ObservedObject var screen: QCLedgerScreen
    @State private var query = ""

    var body: some View {
        let copy = store.copy
        let ordered = orderedSparks(store.book.sparks)
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let matched = needle.isEmpty ? ordered : ordered.filter { sparkMatches($0, query: needle, copy: copy) }
        let wroteSummary = store.book.sparks.contains { $0.kind == .summary && $0.writtenOn == QCLedgerDay.today() }

        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(copy.sparks)
                    .font(.system(size: 26, weight: .bold))
                    .tracking(-0.4)
                    .foregroundStyle(QCPalette.ink)
                if !store.book.sparks.isEmpty {
                    Text("\(store.book.sparks.count)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(QCPalette.muted)
                }
                Spacer(minLength: 0)
            }
            .pageTitleBar()
            QCPageScroll(place: "spark-home", bottom: 28) {
                composer(copy)
                if !wroteSummary {
                    summaryPrompt(copy)
                }
                kindGrid(copy, ordered: ordered)
                QCSparkLookup(text: $query, placeholder: copy.sparkSearch)
                notePreview(copy, matched: matched, searching: !needle.isEmpty)
            }
        }
    }

    private func composer(_ copy: QCLedgerCopy) -> some View {
        Button {
            begin(.idea)
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                Text(copy.sparkHint)
                    .font(.system(size: 17))
                    .foregroundStyle(QCPalette.faint)
                    .frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)
                Text(copy.sparkPlaceholder)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(QCPalette.ink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(QCPalette.pink, in: Capsule())
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(QCPalette.line, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func summaryPrompt(_ copy: QCLedgerCopy) -> some View {
        Button {
            begin(.summary)
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(copy.sparkSummary)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(QCPalette.ink)
                    Text(copy.today)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(QCPalette.muted)
                }
                Spacer(minLength: 8)
                Text(copy.sparkPlaceholder)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(QCPalette.ink)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(QCPalette.wash, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func kindGrid(_ copy: QCLedgerCopy, ordered: [QCSpark]) -> some View {
        let columns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]
        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(QCSparkKind.allCases, id: \.self) { kind in
                let mine = ordered.filter { $0.kind == kind }
                Button {
                    screen.open(.sparkShelf(kind))
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(copy.sparkKindTitle(kind))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(QCPalette.ink)
                                .lineLimit(1)
                            Spacer(minLength: 6)
                            Text("\(mine.count)")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(QCPalette.muted)
                        }
                        Text(mine.first.map { oneLine($0.body) } ?? QCPaperCue.pack(store.book.locale, kind).hint)
                            .font(.system(size: 13))
                            .foregroundStyle(mine.isEmpty ? QCPalette.faint : QCPalette.muted)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, minHeight: 34, alignment: .topLeading)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(QCPalette.line, lineWidth: 1))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func notePreview(_ copy: QCLedgerCopy, matched: [QCSpark], searching: Bool) -> some View {
        let shown = Array(matched.prefix(Self.previewCount))
        let rest = matched.count - shown.count
        return VStack(alignment: .leading, spacing: 10) {
            Text(copy.sparkNotes)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(QCPalette.muted)
            if matched.isEmpty && !searching {
                emptyPaper(copy)
            } else if !matched.isEmpty {
                VStack(spacing: 0) {
                    ForEach(shown) { spark in
                        QCSparkBrief(copy: copy, spark: spark) {
                            screen.open(.spark(id: spark.id))
                        }
                        if spark.id != shown.last?.id || rest > 0 {
                            Rectangle().fill(QCPalette.line).frame(height: 1).padding(.leading, 14)
                        }
                    }
                    if rest > 0 {
                        Button {
                            screen.sparkLookup = query
                            screen.open(.sparkBoard)
                        } label: {
                            HStack(spacing: 8) {
                                Text(copy.filterAll)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(QCPalette.ink)
                                Text("\(matched.count)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(QCPalette.muted)
                                Spacer(minLength: 0)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(QCPalette.faint)
                            }
                            .padding(.horizontal, 14)
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(QCPalette.line, lineWidth: 1))
            }
        }
    }

    private func emptyPaper(_ copy: QCLedgerCopy) -> some View {
        let kinds = [QCSparkKind.diary, .thought, .summary]
        return HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                ForEach(kinds, id: \.self) { _ in
                    Circle()
                        .stroke(QCPalette.line, lineWidth: 1.4)
                        .frame(width: 10, height: 10)
                        .frame(maxWidth: .infinity, minHeight: 48)
                }
            }
            .frame(width: 22)
            Rectangle()
                .fill(QCPalette.pink)
                .frame(width: 2)
            VStack(spacing: 0) {
                ForEach(kinds, id: \.self) { kind in
                    Button { begin(kind) } label: {
                        Text(QCPaperCue.pack(store.book.locale, kind).hint)
                            .font(.system(size: 17))
                            .foregroundStyle(QCPalette.faint)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(QCPalette.line, lineWidth: 1))
    }

    private static let previewCount = 5

    private func begin(_ kind: QCSparkKind) {
        screen.sparkDraftKind = kind.rawValue
        screen.open(.spark(id: nil))
    }

    private func oneLine(_ body: String) -> String {
        body.replacingOccurrences(of: "\n", with: " ")
    }

    private func orderedSparks(_ sparks: [QCSpark]) -> [QCSpark] {
        sparks.sorted { left, right in
            if left.writtenOn != right.writtenOn { return left.writtenOn > right.writtenOn }
            return left.id > right.id
        }
    }
}

private struct QCSparkBrief: View {
    var copy: QCLedgerCopy
    var spark: QCSpark
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(copy.sparkKindTitle(spark.kind))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(QCPalette.muted)
                    .frame(width: 64, alignment: .leading)
                    .lineLimit(1)
                Text(spark.body.replacingOccurrences(of: "\n", with: " "))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(QCPalette.ink)
                    .lineLimit(1)
                if spark.favorite {
                    Text("★")
                        .font(.system(size: 12))
                        .foregroundStyle(QCPalette.ink)
                }
                Spacer(minLength: 8)
                Text(copy.dayChip(spark.writtenOn))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(QCPalette.faint)
                    .lineLimit(1)
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct QCSparkBoardView: View {
    @ObservedObject var store: QCBookStore
    @ObservedObject var screen: QCLedgerScreen
    @State private var query = ""

    var body: some View {
        let copy = store.copy
        let ordered = store.book.sparks.sorted { left, right in
            if left.writtenOn != right.writtenOn { return left.writtenOn > right.writtenOn }
            return left.id > right.id
        }
        let listed = ordered.filter { sparkMatches($0, query: query, copy: copy) }
        let groups = sparkDays(listed, copy: copy)
        QCFormPage(title: copy.sparkNotes, back: copy.back, place: "spark-board") {
            QCSparkLookup(text: $query, placeholder: copy.sparkSearch)
            ForEach(groups) { group in
                Text(group.label)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(QCPalette.muted)
                    .padding(.top, 6)
                VStack(spacing: 0) {
                    ForEach(group.items) { spark in
                        QCSparkBrief(copy: copy, spark: spark) {
                            screen.open(.spark(id: spark.id))
                        }
                        if spark.id != group.items.last?.id {
                            Rectangle().fill(QCPalette.line).frame(height: 1).padding(.leading, 14)
                        }
                    }
                }
                .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(QCPalette.line, lineWidth: 1))
            }
        }
        .onAppear {
            if query.isEmpty, !screen.sparkLookup.isEmpty {
                query = screen.sparkLookup
            }
        }
    }
}

struct QCSparksListView: View {
    @ObservedObject var store: QCBookStore
    @ObservedObject var screen: QCLedgerScreen
    var kind: QCSparkKind
    @State private var query = ""
    @State private var filter = 0
    @State private var timeline = false

    var body: some View {
        let copy = store.copy
        let visible = store.book.sparks.filter { sparkVisible($0, copy: copy) }
        QCFormPage(title: copy.sparkKindTitle(kind), back: copy.back, place: "sparks-\(kind.rawValue)") {
            QCPillButton(title: copy.sparkPlaceholder) {
                screen.sparkDraftKind = kind.rawValue
                screen.open(.spark(id: nil))
            }
            VStack(alignment: .leading, spacing: 8) {
                QCSparkLookup(text: $query, placeholder: copy.sparkSearch)
                QCSparkMode(notes: copy.sparkNotes, timelineTitle: copy.sparkTimeline, timeline: timeline) { timeline = $0 }
                QCSparkFilters(labels: [copy.filterAll, "★ \(copy.sparkFavorite)"], index: filter) { filter = $0 }
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 12)
            .background(Color(red: 1, green: 250 / 255, blue: 251 / 255), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(QCPalette.line, lineWidth: 1))
            .compositingGroup()
            .shadow(color: Color(red: 232 / 255, green: 93 / 255, blue: 117 / 255).opacity(0.07), radius: 14, y: 8)
            .padding(.top, 8)
            if timeline {
                timelineList(copy, sparks: visible)
            } else {
                noteList(copy, sparks: visible)
            }
        }
    }

    private func sparkVisible(_ spark: QCSpark, copy: QCLedgerCopy) -> Bool {
        if spark.kind != kind { return false }
        if filter == 1 && !spark.favorite { return false }
        return sparkMatches(spark, query: query, copy: copy)
    }

    @ViewBuilder
    private func noteList(_ copy: QCLedgerCopy, sparks: [QCSpark]) -> some View {
        let groups = sparkDays(sparks, copy: copy)
        ForEach(groups) { group in
            Text(group.label)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(QCPalette.muted)
                .padding(.top, 6)
            ForEach(group.items) { spark in
                sparkCard(copy, spark: spark)
            }
        }
    }

    @ViewBuilder
    private func timelineList(_ copy: QCLedgerCopy, sparks: [QCSpark]) -> some View {
        let days = timelineDays(sparks)
        ForEach(days, id: \.self) { day in
            Text(sparkDayLabel(day, copy: copy))
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(QCPalette.muted)
                .padding(.top, 6)
            ForEach(sparks.filter { $0.writtenOn == day }) { spark in
                sparkCard(copy, spark: spark)
            }
            ForEach(dayEntries(day)) { entry in
                Button { screen.open(.entry(id: entry.id)) } label: {
                    HStack(spacing: 8) {
                        QCCategoryBadge(
                            style: QCCategoryMarks.style(name: entry.category, marks: store.book.categoryMarks),
                            selected: false,
                            side: 28
                        )
                        Text(entry.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(QCPalette.ink)
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        Text(entryAmount(entry))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(entry.isOut ? QCPalette.down : QCPalette.ink)
                    }
                    .padding(14)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(QCPalette.line, lineWidth: 1))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func sparkCard(_ copy: QCLedgerCopy, spark: QCSpark) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(copy.sparkKindTitle(spark.kind))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(QCPalette.muted)
                Spacer(minLength: 8)
                Button {
                    var next = spark
                    next.favorite.toggle()
                    store.saveSpark(next)
                } label: {
                    Text(spark.favorite ? "★" : "☆")
                        .font(.system(size: 18))
                        .foregroundStyle(QCPalette.ink)
                        .frame(minWidth: 32, minHeight: 32)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(copy.sparkFavorite)
            }
            Button { screen.open(.spark(id: spark.id)) } label: {
                VStack(alignment: .leading, spacing: 8) {
                    if let image = spark.image, let picture = UIImage(data: image) {
                        Image(uiImage: picture)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 160)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    Text(spark.body)
                        .font(.system(size: 16))
                        .foregroundStyle(QCPalette.ink)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if !spark.tags.isEmpty {
                        Text(spark.tags.map { "#\($0)" }.joined(separator: " "))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(QCPalette.muted)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(QCPalette.wash, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func timelineDays(_ sparks: [QCSpark]) -> [String] {
        var days = sparks.map(\.writtenOn)
        if filter == 0 {
            for entry in store.book.entries where !entry.isTransfer && entryMatches(entry) && !days.contains(entry.date) {
                days.append(entry.date)
            }
        }
        return Array(Set(days)).sorted(by: >)
    }

    private func dayEntries(_ day: String) -> [QCEntry] {
        guard filter == 0 else { return [] }
        return store.book.entries.filter { entry in
            entry.date == day && !entry.isTransfer && entryMatches(entry)
        }
    }

    private func entryMatches(_ entry: QCEntry) -> Bool {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if needle.isEmpty { return true }
        return entry.title.localizedCaseInsensitiveContains(needle) || entry.date.contains(needle)
    }

    private func entryAmount(_ entry: QCEntry) -> String {
        if store.book.hideAmounts { return "***" }
        let text = QCLedgerMoney.text(entry.amount, mark: store.book.mark)
        return entry.isOut ? "−\(text)" : "+\(text)"
    }
}

struct QCSparkFormView: View {
    @ObservedObject var store: QCBookStore
    @ObservedObject var screen: QCLedgerScreen
    var sparkID: String?
    @Environment(\.pageBack) private var pageBack
    @State private var bodyText = ""
    @State private var writtenOn = QCLedgerDay.today()
    @State private var kind = 0
    @State private var tags = ""
    @State private var favorite = false
    @State private var image: Data?
    @State private var picking = false
    @State private var looking = false
    @State private var ready = false
    @State private var writingHeight: CGFloat = 280
    @State private var starBump = false

    var body: some View {
        let copy = store.copy
        let kinds = QCSparkKind.allCases
        let existing = store.book.sparks.first { $0.id == sparkID }
        let chips = QCSparkTags.parse(tags)
        let picked = kinds[min(kind, kinds.count - 1)]
        let wash = paperWash(picked)
        let cue = QCPaperCue.pack(store.book.locale, picked)
        VStack(alignment: .leading, spacing: 0) {
            paperHead(copy, kinds: kinds)
            kindStrip(copy, kinds: kinds)
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    paperSheet(copy, cue: cue, picture: image.flatMap { UIImage(data: $0) })
                    if !chips.isEmpty {
                        paperChips(chips)
                            .padding(.horizontal, 6)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 4)
                .padding(.bottom, 24)
                .immediateScroll()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(wash)
        .animation(.easeOut(duration: 0.25), value: kind)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            paperTools(copy, existing: existing, kinds: kinds, wash: wash)
        }
        .onAppear { fill(existing) }
        .sheet(isPresented: $picking) {
            QCPicturePick { data in
                if let data { image = data }
                picking = false
            }
        }
        .fullScreenCover(isPresented: $looking) {
            if let image, let picture = UIImage(data: image) {
                QCPictureLook(image: picture, closeTitle: store.copy.done) { looking = false }
            }
        }
    }

    private func paperHead(_ copy: QCLedgerCopy, kinds: [QCSparkKind]) -> some View {
        HStack(spacing: 8) {
            Button(action: pageBack) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(QCPalette.ink)
                    .frame(width: 36, height: 36)
            }
            .accessibilityLabel(copy.back)
            Text(copy.sparkKindTitle(kinds[min(kind, kinds.count - 1)]))
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(QCPalette.ink)
                .lineLimit(1)
            Spacer(minLength: 8)
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.45)) {
                    favorite.toggle()
                    starBump = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                    withAnimation(.easeOut(duration: 0.16)) { starBump = false }
                }
            } label: {
                Image(systemName: favorite ? "star.fill" : "star")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(favorite ? QCPalette.review : QCPalette.muted)
                    .frame(width: 36, height: 36)
                    .scaleEffect(starBump ? 1.28 : 1)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(copy.sparkFavorite)
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    private func kindStrip(_ copy: QCLedgerCopy, kinds: [QCSparkKind]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(kinds.indices, id: \.self) { index in
                    let on = kind == index
                    Button {
                        withAnimation(.easeOut(duration: 0.25)) { kind = index }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: kindMark(kinds[index]))
                                .font(.system(size: 13, weight: .semibold))
                            Text(copy.sparkKindTitle(kinds[index]))
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundStyle(QCPalette.ink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(on ? QCPalette.pink : Color.white, in: Capsule())
                        .overlay(Capsule().stroke(on ? Color.clear : QCPalette.line, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 6)
        }
    }

    private func kindMark(_ kind: QCSparkKind) -> String {
        switch kind {
        case .idea: return "lightbulb"
        case .diary: return "book"
        case .thought: return "bubble.left"
        case .summary: return "list.bullet"
        }
    }

    private func paperWash(_ kind: QCSparkKind) -> Color {
        switch kind {
        case .idea: return QCPalette.wash
        case .diary: return Color(red: 1, green: 0.97, blue: 0.93)
        case .thought: return QCPalette.neutral
        case .summary: return Color(red: 0.93, green: 0.97, blue: 0.94)
        }
    }

    private func paperSheet(_ copy: QCLedgerCopy, cue: QCPaperCue.QCPack, picture: UIImage?) -> some View {
        let empty = bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return VStack(alignment: .leading, spacing: 16) {
            QCDateField(copy: copy, iso: $writtenOn, label: copy.date, sheet: true)
            if let picture {
                paperPhoto(picture, copy: copy)
            }
            if empty {
                Text(cue.lead)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(QCPalette.muted)
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(cue.lines, id: \.self) { line in
                        Button {
                            bodyText = line
                        } label: {
                            Text(line)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(QCPalette.ink)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(QCPalette.wash, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            HStack(alignment: .top, spacing: 10) {
                VStack(spacing: 16) {
                    ForEach(0..<3, id: \.self) { _ in
                        Circle()
                            .stroke(QCPalette.line, lineWidth: 1.4)
                            .frame(width: 9, height: 9)
                    }
                }
                .padding(.top, 6)
                Rectangle()
                    .fill(QCPalette.pink)
                    .frame(width: 2)
                QCWritingBox(text: $bodyText, placeholder: cue.hint, paper: true) { next in
                    if abs(writingHeight - next) > 1 { writingHeight = next }
                }
                .frame(height: writingHeight)
            }
            if !empty {
                Text(QCPaperCue.tally(store.book.locale, bodyText.count))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(QCPalette.faint)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(16)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(QCPalette.line, lineWidth: 1))
    }

    private func paperPhoto(_ picture: UIImage, copy: QCLedgerCopy) -> some View {
        ZStack(alignment: .topTrailing) {
            Button { looking = true } label: {
                Image(uiImage: picture)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 188)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(8)
                    .padding(.bottom, 16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(QCPalette.line, lineWidth: 1))
                    .shadow(color: QCPalette.ink.opacity(0.08), radius: 10, y: 6)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(copy.sparkPicture)
            Button { image = nil } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(QCPalette.ink)
                    .frame(width: 28, height: 28)
                    .background(Color.white, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(copy.sparkPictureRemove)
            .padding(.top, 4)
            .padding(.trailing, 4)
        }
        .padding(.horizontal, 6)
        .rotationEffect(.degrees(-1.4))
    }

    private func paperChips(_ chips: [String]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(chips, id: \.self) { chip in
                    Text("#\(chip)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(QCPalette.ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(QCPalette.wash, in: Capsule())
                }
            }
        }
    }

    private func paperTools(_ copy: QCLedgerCopy, existing: QCSpark?, kinds: [QCSparkKind], wash: Color) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Button { picking = true } label: {
                    Image(systemName: image == nil ? "photo" : "photo.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(QCPalette.ink)
                        .frame(width: 44, height: 44)
                        .background(QCPalette.wash, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(copy.sparkPicture)
                TextField(copy.sparkTagHint, text: $tags)
                    .font(.system(size: 15))
                    .foregroundStyle(QCPalette.ink)
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(QCPalette.neutral, in: Capsule())
            }
            QCPillButton(title: copy.save, enabled: canSave) { save(existing: existing, kinds: kinds) }
            if existing != nil {
                Button(copy.deleteEntry) {
                    if let sparkID { store.deleteSpark(sparkID) }
                    pageBack()
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(QCPalette.down)
                .frame(maxWidth: .infinity, minHeight: 36)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(wash.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) {
            Rectangle().fill(QCPalette.line).frame(height: 1)
        }
    }

    private var canSave: Bool {
        !bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func fill(_ existing: QCSpark?) {
        guard !ready else { return }
        ready = true
        guard let existing else {
            kind = QCSparkKind.allCases.firstIndex(of: QCSparkKind.read(screen.sparkDraftKind)) ?? 0
            return
        }
        bodyText = existing.body
        writtenOn = existing.writtenOn
        kind = QCSparkKind.allCases.firstIndex(of: existing.kind) ?? 0
        tags = existing.tags.joined(separator: " ")
        favorite = existing.favorite
        image = existing.image
    }

    private func save(existing: QCSpark?, kinds: [QCSparkKind]) {
        guard canSave else { return }
        store.saveSpark(QCSpark(
            id: existing?.id ?? QCLedgerID.make(),
            body: bodyText,
            writtenOn: writtenOn,
            kind: kinds[min(kind, kinds.count - 1)],
            tags: QCSparkTags.parse(tags),
            favorite: favorite,
            image: image
        ))
        pageBack()
    }
}

private struct QCSparkDay: Identifiable {
    var day: String
    var label: String
    var items: [QCSpark]
    var id: String { day }
}

private func sparkDays(_ sparks: [QCSpark], copy: QCLedgerCopy) -> [QCSparkDay] {
    let listed = sparks.sorted { left, right in
        if left.writtenOn != right.writtenOn { return left.writtenOn > right.writtenOn }
        return left.id > right.id
    }
    var groups: [QCSparkDay] = []
    for spark in listed {
        if let index = groups.lastIndex(where: { $0.day == spark.writtenOn }) {
            groups[index].items.append(spark)
        } else {
            groups.append(QCSparkDay(day: spark.writtenOn, label: sparkDayLabel(spark.writtenOn, copy: copy), items: [spark]))
        }
    }
    return groups
}

private enum QCPaperCue {
    struct QCPack {
        var hint: String
        var lead: String
        var lines: [String]
    }

    static func pack(_ locale: QCBookLocale, _ kind: QCSparkKind) -> QCPack {
        let words = table(locale)
        let leaf = words.leaves[kind] ?? words.leaves[.idea]!
        return QCPack(hint: leaf.hint, lead: words.lead, lines: leaf.lines)
    }

    static func tally(_ locale: QCBookLocale, _ count: Int) -> String {
        let text = table(locale).tally
        return text.replacingOccurrences(of: "{count}", with: "\(count)")
    }

    private struct QCLeaf {
        var hint: String
        var lines: [String]
    }

    private struct QCWords {
        var lead: String
        var tally: String
        var leaves: [QCSparkKind: QCLeaf]
    }

    private static func table(_ locale: QCBookLocale) -> QCWords {
        switch locale {
        case .zh:
            return QCWords(lead: "从一笔开始", tally: "{count} 字", leaves: [
                .idea: QCLeaf(hint: "还有一笔没记上", lines: ["这笔下次能少花吗", "想先记下的一笔"]),
                .diary: QCLeaf(hint: "今天这笔钱花在哪", lines: ["为什么会花这一笔", "哪一笔最不该花"]),
                .thought: QCLeaf(hint: "这笔花得值不值", lines: ["还能再省下来吗", "先记着，回头再对"]),
                .summary: QCLeaf(hint: "今天花得最多的是", lines: ["今天一共出去多少", "明天想少花的一笔"]),
            ])
        case .zhHant:
            return QCWords(lead: "從一筆開始", tally: "{count} 字", leaves: [
                .idea: QCLeaf(hint: "還有一筆沒記上", lines: ["這筆下次能少花嗎", "想先記下的一筆"]),
                .diary: QCLeaf(hint: "今天這筆錢花在哪", lines: ["為什麼會花這一筆", "哪一筆最不該花"]),
                .thought: QCLeaf(hint: "這筆花得值不值", lines: ["還能再省下來嗎", "先記著，回頭再對"]),
                .summary: QCLeaf(hint: "今天花得最多的是", lines: ["今天一共出去多少", "明天想少花的一筆"]),
            ])
        case .ja:
            return QCWords(lead: "一件から書く", tally: "{count} 字", leaves: [
                .idea: QCLeaf(hint: "まだ書いていない支出", lines: ["次は減らせるだろうか", "先に残しておきたい一件"]),
                .diary: QCLeaf(hint: "今日このお金は何に使った", lines: ["なぜこの一件を使ったか", "一番いらなかった一件"]),
                .thought: QCLeaf(hint: "この支出は見合ったか", lines: ["まだ減らせるか", "先に書いて、あとで見返す"]),
                .summary: QCLeaf(hint: "今日いちばん使ったものは", lines: ["今日出ていった合計", "明日減らしたい一件"]),
            ])
        case .ko:
            return QCWords(lead: "한 건부터", tally: "{count}자", leaves: [
                .idea: QCLeaf(hint: "아직 적지 않은 지출", lines: ["다음에는 줄일 수 있을까", "먼저 남겨 둘 한 건"]),
                .diary: QCLeaf(hint: "오늘 이 돈은 어디에 썼나", lines: ["왜 이 돈을 썼는지", "가장 쓰지 말았어야 할 한 건"]),
                .thought: QCLeaf(hint: "이 지출은 값어치가 있나", lines: ["더 아낄 수 있나", "먼저 적고 나중에 맞춰 보기"]),
                .summary: QCLeaf(hint: "오늘 가장 많이 쓴 것은", lines: ["오늘 나간 돈을 합치면", "내일 덜 쓰고 싶은 한 건"]),
            ])
        case .es:
            return QCWords(lead: "Empieza por un gasto", tally: "{count} caracteres", leaves: [
                .idea: QCLeaf(hint: "Un gasto que aún no anoté", lines: ["¿La próxima vez se puede gastar menos?", "Un apunte que quiero dejar primero"]),
                .diary: QCLeaf(hint: "En qué se fue este dinero hoy", lines: ["Por qué salió este gasto", "El gasto que no debía salir"]),
                .thought: QCLeaf(hint: "¿Valió este gasto?", lines: ["¿Se puede ahorrar un poco más?", "Lo anoto y lo reviso después"]),
                .summary: QCLeaf(hint: "En qué se fue más el dinero hoy", lines: ["Cuánto salió hoy en total", "Lo que quiero gastar menos mañana"]),
            ])
        case .pt:
            return QCWords(lead: "Começa por uma despesa", tally: "{count} caracteres", leaves: [
                .idea: QCLeaf(hint: "Uma despesa ainda por anotar", lines: ["Da próxima, dá para gastar menos?", "Um lançamento para deixar primeiro"]),
                .diary: QCLeaf(hint: "Em que foi este dinheiro hoje", lines: ["Por que saiu esta despesa", "A despesa que não devia sair"]),
                .thought: QCLeaf(hint: "Esta despesa valeu a pena?", lines: ["Dá para poupar mais um pouco?", "Anoto agora e confiro depois"]),
                .summary: QCLeaf(hint: "Onde foi mais o dinheiro hoje", lines: ["Quanto saiu hoje no total", "O que quero gastar menos amanhã"]),
            ])
        case .fr:
            return QCWords(lead: "Commence par une dépense", tally: "{count} caractères", leaves: [
                .idea: QCLeaf(hint: "Une dépense pas encore notée", lines: ["La prochaine fois, dépenser moins ?", "Une écriture à poser d'abord"]),
                .diary: QCLeaf(hint: "Où est parti cet argent aujourd'hui", lines: ["Pourquoi cette dépense est sortie", "La dépense qui ne devait pas sortir"]),
                .thought: QCLeaf(hint: "Cette dépense en valait-elle la peine", lines: ["On peut encore en garder un peu ?", "Je note, je vérifie plus tard"]),
                .summary: QCLeaf(hint: "Là où l'argent est le plus parti", lines: ["Combien est sorti aujourd'hui", "Ce que je veux dépenser moins demain"]),
            ])
        case .de:
            return QCWords(lead: "Mit einer Ausgabe anfangen", tally: "{count} Zeichen", leaves: [
                .idea: QCLeaf(hint: "Eine Ausgabe, die noch fehlt", lines: ["Lässt sich das nächste Mal weniger ausgeben?", "Eine Buchung, die ich zuerst festhalten will"]),
                .diary: QCLeaf(hint: "Wofür dieses Geld heute ging", lines: ["Warum diese Ausgabe rausging", "Die Ausgabe, die nicht sein musste"]),
                .thought: QCLeaf(hint: "War diese Ausgabe es wert", lines: ["Lässt sich noch etwas sparen?", "Erst notieren, später nachsehen"]),
                .summary: QCLeaf(hint: "Wofür heute das meiste Geld ging", lines: ["Wie viel heute insgesamt rausging", "Was ich morgen weniger ausgeben will"]),
            ])
        case .it:
            return QCWords(lead: "Parti da una spesa", tally: "{count} caratteri", leaves: [
                .idea: QCLeaf(hint: "Una spesa non ancora segnata", lines: ["La prossima volta si può spendere meno?", "Una voce da annotare prima"]),
                .diary: QCLeaf(hint: "Dove sono finiti questi soldi oggi", lines: ["Perché è uscita questa spesa", "La spesa che non doveva uscire"]),
                .thought: QCLeaf(hint: "Questa spesa ne valeva la pena?", lines: ["Si può risparmiare ancora un po'?", "Lo segno e lo controllo dopo"]),
                .summary: QCLeaf(hint: "Dove sono finiti più soldi oggi", lines: ["Quanto è uscito oggi in tutto", "Quello che voglio spendere meno domani"]),
            ])
        case .en:
            return QCWords(lead: "Start from one expense", tally: "{count} characters", leaves: [
                .idea: QCLeaf(hint: "An expense not written down yet", lines: ["Could the next one cost less?", "One entry to set down first"]),
                .diary: QCLeaf(hint: "Where this money went today", lines: ["Why this expense went out", "The one that should not have"]),
                .thought: QCLeaf(hint: "Was this expense worth it", lines: ["Can a little more be kept back?", "Write it now, check it later"]),
                .summary: QCLeaf(hint: "Where most of the money went today", lines: ["How much went out today", "What to spend less on tomorrow"]),
            ])
        }
    }
}

private func sparkDayLabel(_ iso: String, copy: QCLedgerCopy) -> String {
    let today = QCLedgerDay.today()
    if iso == today { return copy.todayWord }
    if iso == QCLedgerDay.adding(days: -1, to: today) { return copy.yesterdayWord }
    return iso
}

private func sparkMatches(_ spark: QCSpark, query: String, copy: QCLedgerCopy) -> Bool {
    let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
    if needle.isEmpty { return true }
    if spark.body.localizedCaseInsensitiveContains(needle) { return true }
    if spark.writtenOn.contains(needle) { return true }
    if copy.sparkKindTitle(spark.kind).localizedCaseInsensitiveContains(needle) { return true }
    return spark.tags.contains { $0.localizedCaseInsensitiveContains(needle) }
}

private struct QCSparkLookup: View {
    @Binding var text: String
    var placeholder: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(QCPalette.down)
            TextField(placeholder, text: $text)
                .font(.system(size: 15))
                .foregroundStyle(QCPalette.ink)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, minHeight: 42, alignment: .leading)
        .background(QCPalette.neutral, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct QCSparkMode: View {
    var notes: String
    var timelineTitle: String
    var timeline: Bool
    var onChange: (Bool) -> Void

    var body: some View {
        HStack(spacing: 2) {
            mode(notes, on: !timeline) { onChange(false) }
            mode(timelineTitle, on: timeline) { onChange(true) }
        }
        .padding(3)
        .background(QCPalette.neutral, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func mode(_ title: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.18)) { action() }
        } label: {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(on ? QCPalette.ink : QCPalette.faint)
                .frame(maxWidth: .infinity, minHeight: 32)
                .background(on ? Color.white : Color.clear, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                .shadow(color: on ? Color.black.opacity(0.06) : Color.clear, radius: 1, y: 1)
        }
        .buttonStyle(.plain)
    }
}

private struct QCSparkFilters: View {
    var labels: [String]
    var index: Int
    var onChange: (Int) -> Void

    var body: some View {
        QCSparkFilterLane(labels: labels, index: index, onChange: onChange)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 32)
    }
}

private struct QCSparkFilterLane: UIViewRepresentable {
    var labels: [String]
    var index: Int
    var onChange: (Int) -> Void

    func makeCoordinator() -> QCCoordinator {
        QCCoordinator(onChange: onChange)
    }

    func makeUIView(context: Context) -> QCFilterLaneHost {
        QCFilterLaneHost()
    }

    func updateUIView(_ host: QCFilterLaneHost, context: Context) {
        context.coordinator.onChange = onChange
        host.render(labels: labels, index: index, target: context.coordinator)
    }

    final class QCCoordinator: NSObject {
        var onChange: (Int) -> Void

        init(onChange: @escaping (Int) -> Void) {
            self.onChange = onChange
        }

        @objc func tap(_ sender: UIButton) {
            onChange(sender.tag)
        }
    }
}

private final class QCFilterLaneHost: UIView {
    private let scroll = UIScrollView()
    private let stack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.showsHorizontalScrollIndicator = false
        scroll.showsVerticalScrollIndicator = false
        scroll.alwaysBounceHorizontal = true
        scroll.alwaysBounceVertical = false
        scroll.isDirectionalLockEnabled = true
        scroll.delaysContentTouches = true
        scroll.canCancelContentTouches = true
        scroll.clipsToBounds = true
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(scroll)
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: trailingAnchor),
            scroll.topAnchor.constraint(equalTo: topAnchor),
            scroll.bottomAnchor.constraint(equalTo: bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -8),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            stack.heightAnchor.constraint(equalTo: scroll.frameLayoutGuide.heightAnchor),
        ])
        setContentHuggingPriority(.defaultLow, for: .horizontal)
        setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    required init?(coder: NSCoder) { nil }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 32)
    }

    func render(labels: [String], index: Int, target: QCSparkFilterLane.QCCoordinator) {
        if stack.arrangedSubviews.count != labels.count {
            stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
            for item in labels.indices {
                let button = UIButton(type: .system)
                button.tag = item
                button.setContentHuggingPriority(.required, for: .horizontal)
                button.setContentCompressionResistancePriority(.required, for: .horizontal)
                button.addTarget(target, action: #selector(QCSparkFilterLane.QCCoordinator.tap(_:)), for: .touchUpInside)
                stack.addArrangedSubview(button)
            }
        }
        for item in labels.indices {
            guard let button = stack.arrangedSubviews[item] as? UIButton else { continue }
            let on = item == index
            var config = UIButton.Configuration.plain()
            config.title = labels[item]
            config.baseForegroundColor = on
                ? UIColor(red: 11 / 255, green: 5 / 255, blue: 29 / 255, alpha: 1)
                : UIColor(red: 155 / 255, green: 150 / 255, blue: 163 / 255, alpha: 1)
            config.background.backgroundColor = on
                ? UIColor(red: 1, green: 179 / 255, blue: 199 / 255, alpha: 1)
                : .clear
            config.background.cornerRadius = 14
            config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 6, bottom: 4, trailing: 6)
            config.titlePadding = 0
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = .systemFont(ofSize: 13, weight: .semibold)
                return outgoing
            }
            button.configuration = config
        }
    }
}

private struct QCPictureLook: View {
    var image: UIImage
    var closeTitle: String
    var onClose: () -> Void
    @State private var dragY: CGFloat = 0

    var body: some View {
        let fade = max(0.2, 1 - Double(dragY) / 320)
        ZStack(alignment: .top) {
            Color(red: 11 / 255, green: 5 / 255, blue: 29 / 255).opacity(fade).ignoresSafeArea()
            VStack(spacing: 12) {
                HStack {
                    Spacer()
                    Button(action: onClose) {
                        Text("×  \(closeTitle)")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(QCPalette.ink)
                            .padding(.horizontal, 16)
                            .frame(minHeight: 44)
                            .background(Color.white, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 20)
            .offset(y: dragY)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 12)
                .onChanged { value in
                    let dy = value.translation.height
                    dragY = dy > 8 && dy > abs(value.translation.width) ? dy : 0
                }
                .onEnded { value in
                    let dy = value.translation.height
                    if dy > 72 && dy > abs(value.translation.width) {
                        onClose()
                    }
                    withAnimation(.easeOut(duration: 0.22)) { dragY = 0 }
                }
        )
    }
}

private struct QCWritingBox: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var paper = false
    var onHeight: (CGFloat) -> Void = { _ in }

    func makeUIView(context: Context) -> QCWritingHost {
        let host = QCWritingHost(paper: paper)
        host.onHeight = onHeight
        host.textView.delegate = context.coordinator
        host.textView.text = text
        host.hint.text = placeholder
        host.hint.isHidden = !text.isEmpty
        return host
    }

    func updateUIView(_ host: QCWritingHost, context: Context) {
        context.coordinator.text = $text
        host.onHeight = onHeight
        if host.textView.text != text { host.textView.text = text }
        if host.hint.text != placeholder { host.hint.text = placeholder }
        host.hint.isHidden = !host.textView.text.isEmpty
        host.fit()
    }

    func makeCoordinator() -> QCCoordinator {
        QCCoordinator(text: $text)
    }

    final class QCCoordinator: NSObject, UITextViewDelegate {
        var text: Binding<String>

        init(text: Binding<String>) {
            self.text = text
        }

        func textViewDidChange(_ view: UITextView) {
            let next = String(view.text.prefix(2000))
            if view.text != next { view.text = next }
            if text.wrappedValue != next { text.wrappedValue = next }
            guard let host = view.superview as? QCWritingHost else { return }
            host.hint.isHidden = !next.isEmpty
            host.fit()
        }
    }
}

private final class QCWritingHost: UIView, UIGestureRecognizerDelegate {
    let textView = UITextView()
    let hint = UILabel()
    var onHeight: (CGFloat) -> Void = { _ in }
    private var paper = false
    private var held: CGFloat = 280

    init(paper: Bool) {
        super.init(frame: .zero)
        self.paper = paper
        let ink = UIColor(red: 11 / 255, green: 5 / 255, blue: 29 / 255, alpha: 1)
        let size: CGFloat = paper ? 18 : 16
        backgroundColor = paper ? .clear : .white
        layer.cornerRadius = paper ? 0 : 14
        layer.borderWidth = paper ? 0 : 1
        layer.borderColor = UIColor(red: 240 / 255, green: 221 / 255, blue: 227 / 255, alpha: 1).cgColor
        clipsToBounds = true
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = .systemFont(ofSize: size)
        textView.textColor = ink
        textView.tintColor = ink
        textView.backgroundColor = .clear
        textView.textContainerInset = paper
            ? UIEdgeInsets(top: 0, left: 0, bottom: 12, right: 0)
            : UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        if paper {
            textView.textContainer.lineFragmentPadding = 0
            textView.isScrollEnabled = false
            textView.alwaysBounceVertical = false
            let slide = UIPanGestureRecognizer(target: self, action: #selector(slideAway))
            slide.cancelsTouchesInView = false
            slide.delaysTouchesBegan = false
            slide.delegate = self
            textView.addGestureRecognizer(slide)
        }
        textView.keyboardDismissMode = .onDrag
        hint.translatesAutoresizingMaskIntoConstraints = false
        hint.font = .systemFont(ofSize: size)
        hint.textColor = UIColor(red: 155 / 255, green: 150 / 255, blue: 163 / 255, alpha: 1)
        hint.isUserInteractionEnabled = false
        addSubview(textView)
        addSubview(hint)
        let hintX: CGFloat = paper ? 0 : 15
        let hintY: CGFloat = paper ? 0 : 12
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: topAnchor),
            textView.leadingAnchor.constraint(equalTo: leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor),
            hint.topAnchor.constraint(equalTo: topAnchor, constant: hintY),
            hint.leadingAnchor.constraint(equalTo: leadingAnchor, constant: hintX),
            hint.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
        ])
        setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        setContentHuggingPriority(.defaultLow, for: .vertical)
        setContentCompressionResistancePriority(.defaultLow, for: .vertical)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        fit()
    }

    func fit() {
        guard paper else { return }
        let width = textView.bounds.width > 1 ? textView.bounds.width : bounds.width
        guard width > 1 else { return }
        let fitting = textView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
        let next = max(280, ceil(fitting))
        guard abs(next - held) > 1 else { return }
        held = next
        let report = onHeight
        DispatchQueue.main.async { report(next) }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        true
    }

    @objc private func slideAway(_ gesture: UIPanGestureRecognizer) {
        guard gesture.state == .began || gesture.state == .changed else { return }
        let moved = gesture.translation(in: textView)
        guard abs(moved.y) > 8, abs(moved.y) > abs(moved.x) else { return }
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: layer.borderWidth == 0 ? 280 : 168)
    }
}

private struct QCPicturePick: UIViewControllerRepresentable {
    var onPick: (Data?) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ controller: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> QCCoordinator {
        QCCoordinator(onPick: onPick)
    }

    final class QCCoordinator: NSObject, PHPickerViewControllerDelegate {
        var onPick: (Data?) -> Void

        init(onPick: @escaping (Data?) -> Void) {
            self.onPick = onPick
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else {
                onPick(nil)
                return
            }
            provider.loadObject(ofClass: UIImage.self) { object, _ in
                let data = (object as? UIImage).flatMap { QCPictureFit.jpeg($0) }
                DispatchQueue.main.async { self.onPick(data) }
            }
        }
    }
}

private enum QCPictureFit {
    static func jpeg(_ image: UIImage) -> Data? {
        let longest = max(image.size.width, image.size.height)
        let scale = longest > 1280 ? 1280 / longest : 1
        let target = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: target)
        let drawn = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
        return drawn.jpegData(compressionQuality: 0.72)
    }
}
