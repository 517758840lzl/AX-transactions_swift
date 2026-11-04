//
//  SparkPage.swift
//  transaction
//

import Combine
import PhotosUI
import SwiftUI
import UIKit

struct SparksListView: View {
    @ObservedObject var store: BookStore
    @ObservedObject var screen: LedgerScreen
    @State private var draft = ""
    @State private var draftDay = LedgerDay.today()
    @State private var draftKind = 0
    @State private var draftTags = ""
    @State private var draftFavorite = false
    @State private var draftImage: Data?
    @State private var picking = false
    @State private var looking = false
    @State private var query = ""
    @State private var filter = 0
    @State private var timeline = false

    var body: some View {
        let copy = store.copy
        let kinds = SparkKind.allCases
        let visible = store.book.sparks.filter { sparkVisible($0, copy: copy) }
        FormPage(title: copy.sparks, back: copy.back) {
            ChoiceRow(labels: kinds.map { copy.sparkKindTitle($0) }, index: draftKind, columns: 2) { draftKind = $0 }
            WritingBox(text: $draft, placeholder: copy.sparkPlaceholder)
            FieldLabel(text: copy.sparkTags)
            LedgerField(text: $draftTags, placeholder: copy.sparkTagHint)
            FieldLabel(text: copy.date)
            DateField(copy: copy, iso: $draftDay, label: copy.date)
            pictureBox(copy, data: draftImage, pick: { picking = true }, clear: { draftImage = nil })
            Button {
                draftFavorite.toggle()
            } label: {
                Text(draftFavorite ? "★ \(copy.sparkFavorite)" : "☆ \(copy.sparkFavorite)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(draftFavorite ? Palette.ink : Palette.muted)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.plain)
            PillButton(title: copy.save, enabled: !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) {
                store.saveSpark(Spark(
                    id: LedgerID.make(),
                    body: draft,
                    writtenOn: draftDay,
                    kind: kinds[min(draftKind, kinds.count - 1)],
                    tags: SparkTags.parse(draftTags),
                    favorite: draftFavorite,
                    image: draftImage
                ))
                draft = ""
                draftTags = ""
                draftFavorite = false
                draftImage = nil
                draftDay = LedgerDay.today()
            }
            VStack(alignment: .leading, spacing: 8) {
                SparkLookup(text: $query, placeholder: copy.sparkSearch)
                SparkMode(notes: copy.sparkNotes, timelineTitle: copy.sparkTimeline, timeline: timeline) { timeline = $0 }
                SparkFilters(labels: [copy.filterAll, copy.sparkIdea, copy.sparkDiary, copy.sparkThought, copy.sparkSummary, "★ \(copy.sparkFavorite)"], index: filter) { filter = $0 }
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 12)
            .background(Color(red: 1, green: 250 / 255, blue: 251 / 255), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Palette.line, lineWidth: 1))
            .compositingGroup()
            .shadow(color: Color(red: 232 / 255, green: 93 / 255, blue: 117 / 255).opacity(0.07), radius: 14, y: 8)
            .padding(.top, 8)
            if timeline {
                timelineList(copy, sparks: visible)
            } else {
                noteList(copy, sparks: visible)
            }
        }
        .sheet(isPresented: $picking) {
            PicturePick { data in
                if let data { draftImage = data }
                picking = false
            }
        }
        .fullScreenCover(isPresented: $looking) {
            if let draftImage, let picture = UIImage(data: draftImage) {
                PictureLook(image: picture, closeTitle: store.copy.done) { looking = false }
            }
        }
    }

    private func sparkVisible(_ spark: Spark, copy: LedgerCopy) -> Bool {
        if filter == 5 && !spark.favorite { return false }
        if (1...4).contains(filter), spark.kind != SparkKind.allCases[filter - 1] { return false }
        return sparkMatches(spark, query: query, copy: copy)
    }

    @ViewBuilder
    private func noteList(_ copy: LedgerCopy, sparks: [Spark]) -> some View {
        let groups = sparkDays(sparks, copy: copy)
        ForEach(groups) { group in
            Text(group.label)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Palette.muted)
                .padding(.top, 6)
            ForEach(group.items) { spark in
                sparkCard(copy, spark: spark)
            }
        }
    }

    @ViewBuilder
    private func timelineList(_ copy: LedgerCopy, sparks: [Spark]) -> some View {
        let days = timelineDays(sparks)
        ForEach(days, id: \.self) { day in
            Text(sparkDayLabel(day, copy: copy))
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Palette.muted)
                .padding(.top, 6)
            ForEach(sparks.filter { $0.writtenOn == day }) { spark in
                sparkCard(copy, spark: spark)
            }
            ForEach(dayEntries(day)) { entry in
                Button { screen.open(.entry(id: entry.id)) } label: {
                    HStack(spacing: 8) {
                        CategoryBadge(
                            style: CategoryMarks.style(name: entry.category, marks: store.book.categoryMarks),
                            selected: false,
                            side: 28
                        )
                        Text(entry.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Palette.ink)
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        Text(entryAmount(entry))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(entry.isOut ? Palette.down : Palette.ink)
                    }
                    .padding(14)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Palette.line, lineWidth: 1))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func sparkCard(_ copy: LedgerCopy, spark: Spark) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(copy.sparkKindTitle(spark.kind))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Palette.muted)
                Spacer(minLength: 8)
                Button {
                    var next = spark
                    next.favorite.toggle()
                    store.saveSpark(next)
                } label: {
                    Text(spark.favorite ? "★" : "☆")
                        .font(.system(size: 18))
                        .foregroundStyle(Palette.ink)
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
                        .foregroundStyle(Palette.ink)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if !spark.tags.isEmpty {
                        Text(spark.tags.map { "#\($0)" }.joined(separator: " "))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Palette.muted)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Palette.wash, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func timelineDays(_ sparks: [Spark]) -> [String] {
        var days = sparks.map(\.writtenOn)
        if filter == 0 {
            for entry in store.book.entries where !entry.isTransfer && entryMatches(entry) && !days.contains(entry.date) {
                days.append(entry.date)
            }
        }
        return Array(Set(days)).sorted(by: >)
    }

    private func dayEntries(_ day: String) -> [Entry] {
        store.book.entries.filter { entry in
            entry.date == day && !entry.isTransfer && (filter != 0 || entryMatches(entry))
        }
    }

    private func entryMatches(_ entry: Entry) -> Bool {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if needle.isEmpty { return true }
        return entry.title.localizedCaseInsensitiveContains(needle) || entry.date.contains(needle)
    }

    private func entryAmount(_ entry: Entry) -> String {
        if store.book.hideAmounts { return "***" }
        let text = LedgerMoney.text(entry.amount, mark: store.book.mark)
        return entry.isOut ? "−\(text)" : "+\(text)"
    }

    private func pictureBox(_ copy: LedgerCopy, data: Data?, pick: @escaping () -> Void, clear: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let data, let picture = UIImage(data: data) {
                Button { looking = true } label: {
                    Image(uiImage: picture)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 140)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(copy.sparkPicture)
                Button(copy.sparkPictureRemove, action: clear)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Palette.down)
            }
            Button(copy.sparkPicture, action: pick)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Palette.ink)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Palette.line, lineWidth: 1))
        }
    }
}

struct SparkFormView: View {
    @ObservedObject var store: BookStore
    var sparkID: String?
    @Environment(\.pageBack) private var pageBack
    @State private var bodyText = ""
    @State private var writtenOn = LedgerDay.today()
    @State private var kind = 0
    @State private var tags = ""
    @State private var favorite = false
    @State private var image: Data?
    @State private var picking = false
    @State private var looking = false
    @State private var ready = false

    var body: some View {
        let copy = store.copy
        let kinds = SparkKind.allCases
        let existing = store.book.sparks.first { $0.id == sparkID }
        FormPage(title: copy.sparks, back: copy.back) {
            ChoiceRow(labels: kinds.map { copy.sparkKindTitle($0) }, index: kind, columns: 2) { kind = $0 }
            WritingBox(text: $bodyText, placeholder: copy.sparkPlaceholder)
            FieldLabel(text: copy.sparkTags)
            LedgerField(text: $tags, placeholder: copy.sparkTagHint)
            FieldLabel(text: copy.date)
            DateField(copy: copy, iso: $writtenOn, label: copy.date)
            if let image, let picture = UIImage(data: image) {
                Button { looking = true } label: {
                    Image(uiImage: picture)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 160)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(copy.sparkPicture)
                Button(copy.sparkPictureRemove) { self.image = nil }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Palette.down)
            }
            Button(copy.sparkPicture) { picking = true }
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Palette.ink)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Palette.line, lineWidth: 1))
            Button {
                favorite.toggle()
            } label: {
                Text(favorite ? "★ \(copy.sparkFavorite)" : "☆ \(copy.sparkFavorite)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(favorite ? Palette.ink : Palette.muted)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.plain)
            PillButton(title: copy.save, enabled: canSave) { save(existing: existing, kinds: kinds) }
            if existing != nil {
                Button(copy.deleteEntry) {
                    if let sparkID { store.deleteSpark(sparkID) }
                    pageBack()
                }
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(Palette.down)
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear { fill(existing) }
        .sheet(isPresented: $picking) {
            PicturePick { data in
                if let data { image = data }
                picking = false
            }
        }
        .fullScreenCover(isPresented: $looking) {
            if let image, let picture = UIImage(data: image) {
                PictureLook(image: picture, closeTitle: store.copy.done) { looking = false }
            }
        }
    }

    private var canSave: Bool {
        !bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func fill(_ existing: Spark?) {
        guard !ready else { return }
        ready = true
        guard let existing else { return }
        bodyText = existing.body
        writtenOn = existing.writtenOn
        kind = SparkKind.allCases.firstIndex(of: existing.kind) ?? 0
        tags = existing.tags.joined(separator: " ")
        favorite = existing.favorite
        image = existing.image
    }

    private func save(existing: Spark?, kinds: [SparkKind]) {
        guard canSave else { return }
        store.saveSpark(Spark(
            id: existing?.id ?? LedgerID.make(),
            body: bodyText,
            writtenOn: writtenOn,
            kind: kinds[min(kind, kinds.count - 1)],
            tags: SparkTags.parse(tags),
            favorite: favorite,
            image: image
        ))
        pageBack()
    }
}

private struct SparkDay: Identifiable {
    var day: String
    var label: String
    var items: [Spark]
    var id: String { day }
}

private func sparkDays(_ sparks: [Spark], copy: LedgerCopy) -> [SparkDay] {
    let listed = sparks.sorted { left, right in
        if left.writtenOn != right.writtenOn { return left.writtenOn > right.writtenOn }
        return left.id > right.id
    }
    var groups: [SparkDay] = []
    for spark in listed {
        if let index = groups.lastIndex(where: { $0.day == spark.writtenOn }) {
            groups[index].items.append(spark)
        } else {
            groups.append(SparkDay(day: spark.writtenOn, label: sparkDayLabel(spark.writtenOn, copy: copy), items: [spark]))
        }
    }
    return groups
}

private func sparkDayLabel(_ iso: String, copy: LedgerCopy) -> String {
    let today = LedgerDay.today()
    if iso == today { return copy.todayWord }
    if iso == LedgerDay.adding(days: -1, to: today) { return copy.yesterdayWord }
    return iso
}

private func sparkMatches(_ spark: Spark, query: String, copy: LedgerCopy) -> Bool {
    let needle = query.trimmingCharacters(in: .whitespacesAndNewlines)
    if needle.isEmpty { return true }
    if spark.body.localizedCaseInsensitiveContains(needle) { return true }
    if spark.writtenOn.contains(needle) { return true }
    if copy.sparkKindTitle(spark.kind).localizedCaseInsensitiveContains(needle) { return true }
    return spark.tags.contains { $0.localizedCaseInsensitiveContains(needle) }
}

private struct SparkLookup: View {
    @Binding var text: String
    var placeholder: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Palette.down)
            TextField(placeholder, text: $text)
                .font(.system(size: 15))
                .foregroundStyle(Palette.ink)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, minHeight: 42, alignment: .leading)
        .background(Palette.neutral, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct SparkMode: View {
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
        .background(Palette.neutral, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func mode(_ title: String, on: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.18)) { action() }
        } label: {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(on ? Palette.ink : Palette.faint)
                .frame(maxWidth: .infinity, minHeight: 32)
                .background(on ? Color.white : Color.clear, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                .shadow(color: on ? Color.black.opacity(0.06) : Color.clear, radius: 1, y: 1)
        }
        .buttonStyle(.plain)
    }
}

private struct SparkFilters: View {
    var labels: [String]
    var index: Int
    var onChange: (Int) -> Void

    var body: some View {
        SparkFilterLane(labels: labels, index: index, onChange: onChange)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 32)
    }
}

private struct SparkFilterLane: UIViewRepresentable {
    var labels: [String]
    var index: Int
    var onChange: (Int) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onChange: onChange)
    }

    func makeUIView(context: Context) -> FilterLaneHost {
        FilterLaneHost()
    }

    func updateUIView(_ host: FilterLaneHost, context: Context) {
        context.coordinator.onChange = onChange
        host.render(labels: labels, index: index, target: context.coordinator)
    }

    final class Coordinator: NSObject {
        var onChange: (Int) -> Void

        init(onChange: @escaping (Int) -> Void) {
            self.onChange = onChange
        }

        @objc func tap(_ sender: UIButton) {
            onChange(sender.tag)
        }
    }
}

private final class FilterLaneHost: UIView {
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

    func render(labels: [String], index: Int, target: SparkFilterLane.Coordinator) {
        if stack.arrangedSubviews.count != labels.count {
            stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
            for item in labels.indices {
                let button = UIButton(type: .system)
                button.tag = item
                button.setContentHuggingPriority(.required, for: .horizontal)
                button.setContentCompressionResistancePriority(.required, for: .horizontal)
                button.addTarget(target, action: #selector(SparkFilterLane.Coordinator.tap(_:)), for: .touchUpInside)
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

private struct PictureLook: View {
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
                            .foregroundStyle(Palette.ink)
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

private struct WritingBox: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String

    func makeUIView(context: Context) -> WritingHost {
        let host = WritingHost()
        host.textView.delegate = context.coordinator
        host.textView.font = .systemFont(ofSize: 16)
        host.textView.textColor = UIColor(red: 11 / 255, green: 5 / 255, blue: 29 / 255, alpha: 1)
        host.textView.tintColor = host.textView.textColor
        host.textView.backgroundColor = .clear
        host.textView.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        host.textView.text = text
        host.hint.text = placeholder
        host.hint.isHidden = !text.isEmpty
        return host
    }

    func updateUIView(_ host: WritingHost, context: Context) {
        context.coordinator.text = $text
        if host.textView.text != text { host.textView.text = text }
        if host.hint.text != placeholder { host.hint.text = placeholder }
        host.hint.isHidden = !host.textView.text.isEmpty
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var text: Binding<String>

        init(text: Binding<String>) {
            self.text = text
        }

        func textViewDidChange(_ view: UITextView) {
            let next = String(view.text.prefix(2000))
            if view.text != next { view.text = next }
            if text.wrappedValue != next { text.wrappedValue = next }
            (view.superview as? WritingHost)?.hint.isHidden = !next.isEmpty
        }
    }
}

private final class WritingHost: UIView {
    let textView = UITextView()
    let hint = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        layer.cornerRadius = 14
        layer.borderWidth = 1
        layer.borderColor = UIColor(red: 240 / 255, green: 221 / 255, blue: 227 / 255, alpha: 1).cgColor
        clipsToBounds = true
        textView.translatesAutoresizingMaskIntoConstraints = false
        hint.translatesAutoresizingMaskIntoConstraints = false
        hint.font = .systemFont(ofSize: 16)
        hint.textColor = UIColor(red: 110 / 255, green: 104 / 255, blue: 120 / 255, alpha: 1)
        hint.isUserInteractionEnabled = false
        addSubview(textView)
        addSubview(hint)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: topAnchor),
            textView.leadingAnchor.constraint(equalTo: leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor),
            hint.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            hint.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15),
            hint.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
        ])
        setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        setContentHuggingPriority(.defaultLow, for: .vertical)
        setContentCompressionResistancePriority(.defaultLow, for: .vertical)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: 168)
    }
}

private struct PicturePick: UIViewControllerRepresentable {
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

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
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
                let data = (object as? UIImage).flatMap { PictureFit.jpeg($0) }
                DispatchQueue.main.async { self.onPick(data) }
            }
        }
    }
}

private enum PictureFit {
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
