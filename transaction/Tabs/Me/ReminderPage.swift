//
//  ReminderPage.swift
//  transaction
//

import SwiftUI
import UIKit
import UserNotifications
import Combine

struct ReminderPage: View {
    @ObservedObject var store: BookStore
    @StateObject private var gate = ReminderGate()
    @Environment(\.pageBack) private var pageBack
    @State private var pickingTime = false

    var body: some View {
        let copy = store.copy
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    SubpageHead(title: copy.reminderTitle, back: copy.back) { pageBack() }
                    PanelCard {
                        HStack(spacing: 12) {
                            Text(copy.reminderDaily)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Palette.ink)
                            Spacer(minLength: 8)
                            Toggle("", isOn: Binding(
                                get: { store.book.dailyReminder },
                                set: { store.setDailyReminder($0) }
                            ))
                            .labelsHidden()
                            .tint(Palette.pink)
                        }
                    }
                    Text(copy.reminderTime)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Palette.muted)
                    Button {
                        pickingTime = true
                    } label: {
                        Text(Self.clockLabel(hour: store.book.reminderHour, minute: store.book.reminderMinute))
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Palette.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .frame(minHeight: 52)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 26, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(Palette.line, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    Text(copy.reminderNote)
                        .font(.system(size: 13))
                        .foregroundStyle(Palette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                    if gate.denied {
                        Button {
                            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                            UIApplication.shared.open(url)
                        } label: {
                            Text(copy.reminderDenied.replacingOccurrences(of: "{name}", with: BundleTitle.current))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Palette.down)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .background(Palette.down.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 32)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            if pickingTime {
                timePopup(copy)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Palette.stage)
        .onAppear { gate.reload() }
        .onReceive(NotificationCenter.default.publisher(for: .reminderAccessChanged)) { _ in
            gate.reload()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            gate.reload()
        }
    }

    private func timePopup(_ copy: LedgerCopy) -> some View {
        ZStack {
            Color.black.opacity(0.28)
                .ignoresSafeArea()
                .onTapGesture { pickingTime = false }
            VStack(spacing: 0) {
                ClockWheel(date: Binding(
                    get: { Self.clock(hour: store.book.reminderHour, minute: store.book.reminderMinute) },
                    set: { value in
                        let parts = Calendar.current.dateComponents([.hour, .minute], from: value)
                        store.setReminderTime(hour: parts.hour ?? 21, minute: parts.minute ?? 30)
                    }
                ))
                .frame(maxWidth: .infinity)
                .frame(height: 216)
                Button(copy.done) { pickingTime = false }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
            }
            .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .padding(.horizontal, 18)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private static func clock(hour: Int, minute: Int) -> Date {
        var parts = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        parts.hour = hour
        parts.minute = minute
        return Calendar.current.date(from: parts) ?? Date()
    }

    private static func clockLabel(hour: Int, minute: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: clock(hour: hour, minute: minute))
    }
}

struct ClockWheel: UIViewRepresentable {
    @Binding var date: Date

    func makeUIView(context: Context) -> UIView {
        let box = UIView()
        let picker = UIDatePicker()
        picker.datePickerMode = .time
        picker.preferredDatePickerStyle = .wheels
        picker.minuteInterval = 1
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .valueChanged)
        box.addSubview(picker)
        NSLayoutConstraint.activate([
            picker.leadingAnchor.constraint(equalTo: box.leadingAnchor),
            picker.trailingAnchor.constraint(equalTo: box.trailingAnchor),
            picker.topAnchor.constraint(equalTo: box.topAnchor),
            picker.bottomAnchor.constraint(equalTo: box.bottomAnchor),
        ])
        context.coordinator.picker = picker
        return box
    }

    func updateUIView(_ box: UIView, context: Context) {
        context.coordinator.date = $date
        guard let picker = context.coordinator.picker else { return }
        if abs(picker.date.timeIntervalSince(date)) >= 60 {
            picker.setDate(date, animated: false)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(date: $date)
    }

    final class Coordinator: NSObject {
        var date: Binding<Date>
        weak var picker: UIDatePicker?
        init(date: Binding<Date>) { self.date = date }
        @objc func changed(_ picker: UIDatePicker) {
            date.wrappedValue = picker.date
        }
    }
}

final class ReminderGate: ObservableObject {
    @Published var denied = false

    func reload() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            let blocked = settings.authorizationStatus == .denied
            Task { @MainActor in
                self.denied = blocked
            }
        }
    }
}
