// Copyright (C) 2026 ProcessLeash contributors
// Licensed under the GNU General Public License v3.0

import SwiftUI
import AppKit

struct RunningApp: Identifiable {
    let id: pid_t
    let name: String
    let icon: NSImage?
    let bundleIdentifier: String?
}

@MainActor
final class AppModel: ObservableObject {
    @Published var apps: [RunningApp] = []
    @Published var filter: String = ""
    @Published var limiters: [pid_t: CPULimiter] = [:]
    /// Default — no throttling (100%).
    let defaultPercent: Double = 100
    private var storedPercents: [String: Double] = [:]
    private let storedPercentsKey = "ProcessLeash.storedPercents"

    init() {
        if let dict = UserDefaults.standard.dictionary(forKey: storedPercentsKey) as? [String: Double] {
            storedPercents = dict
        }
    }

    func refreshApps() {
        let running = NSWorkspace.shared.runningApplications
            .filter { !$0.isTerminated }
            .compactMap { app -> RunningApp? in
                guard let name = app.localizedName else { return nil }
                return RunningApp(
                    id: app.processIdentifier,
                    name: name,
                    icon: app.icon,
                    bundleIdentifier: app.bundleIdentifier
                )
            }
            .sorted { $0.name.lowercased() < $1.name.lowercased() }

        apps = running
    }

    private func storageKey(for app: RunningApp) -> String {
        if let bundleID = app.bundleIdentifier, !bundleID.isEmpty {
            return "bundle:\(bundleID)"
        }
        return "name:\(app.name)"
    }

    private func storedPercent(for app: RunningApp) -> Double {
        storedPercents[storageKey(for: app)] ?? defaultPercent
    }

    func limiter(for app: RunningApp) -> CPULimiter {
        if let existing = limiters[app.id] { return existing }
        let limiter = CPULimiter(pid: app.id, percent: storedPercent(for: app))
        limiters[app.id] = limiter
        return limiter
    }

    func persistPercent(for app: RunningApp, percent: Double) {
        storedPercents[storageKey(for: app)] = percent
        UserDefaults.standard.setValue(storedPercents, forKey: storedPercentsKey)
    }

    func stopAll() {
        for limiter in limiters.values {
            limiter.stop()
        }
    }

    func resetAllToDefault() {
        for limiter in limiters.values {
            limiter.percent = defaultPercent
            limiter.stop()
        }
        storedPercents.removeAll()
        UserDefaults.standard.removeObject(forKey: storedPercentsKey)
    }
}

struct CompactSlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double> = 0...100
    var step: Double = 1
    var onChange: (Double) -> Void = { _ in }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let progress = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 4)

                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: max(0, min(width, width * progress)), height: 4)

                Circle()
                    .fill(Color.white)
                    .shadow(radius: 1)
                    .frame(width: 18, height: 18)
                    .offset(x: max(0, min(width - 18, width * progress - 9)))
            }
            .frame(height: 18, alignment: .center)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let x = min(max(0, gesture.location.x), width)
                        var newValue = Double(x / width) * (range.upperBound - range.lowerBound) + range.lowerBound
                        newValue = (newValue / step).rounded() * step
                        newValue = min(max(range.lowerBound, newValue), range.upperBound)
                        value = newValue
                        onChange(newValue)
                    }
            )
        }
    }
}

struct ContentView: View {
    @StateObject private var model = AppModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                TextField("Filter", text: $model.filter)
                    .textFieldStyle(.roundedBorder)
                Button("Reset all") { model.resetAllToDefault() }
                    .controlSize(.small)
                Button("Refresh") { model.refreshApps() }
                    .controlSize(.small)
            }

            let shown = model.apps.filter {
                model.filter.isEmpty || $0.name.localizedCaseInsensitiveContains(model.filter)
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(shown) { app in
                        AppRow(
                            app: app,
                            limiter: model.limiter(for: app),
                            defaultPercent: model.defaultPercent,
                            onPercentChange: { model.persistPercent(for: app, percent: $0) }
                        )
                        .padding(.vertical, 4)
                        Divider()
                    }
                }
                .padding(.horizontal, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: 420, height: 520)

            HStack {
                Button("Stop all") { model.stopAll() }
                Spacer()
                Button("Quit") {
                    model.stopAll()
                    NSApp.terminate(nil)
                }
            }
        }
        .padding(12)
        .onAppear { model.refreshApps() }
    }
}

struct AppRow: View {
    let app: RunningApp
    @ObservedObject var limiter: CPULimiter
    let defaultPercent: Double
    let onPercentChange: (Double) -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            if let icon = app.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 18, height: 18)
                    .cornerRadius(3)
            } else {
                Image(systemName: "app.dashed")
                    .frame(width: 18, height: 18)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(app.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Text("PID \(app.id)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 6) {
                    Button {
                        limiter.percent = max(0, limiter.percent - 5)
                        onPercentChange(limiter.percent)
                    } label: {
                        Text("−")
                            .frame(width: 16, height: 16)
                    }
                    .font(.system(size: 12, weight: .bold))
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    CompactSlider(value: $limiter.percent, onChange: onPercentChange)
                        .frame(width: 170, height: 20)

                    Button {
                        limiter.percent = min(100, limiter.percent + 5)
                        onPercentChange(limiter.percent)
                    } label: {
                        Text("+")
                            .frame(width: 16, height: 16)
                    }
                    .font(.system(size: 12, weight: .bold))
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Text("\(Int(limiter.percent))%")
                        .font(.system(size: 10))
                        .frame(width: 32, alignment: .trailing)
                }
                HStack(spacing: 6) {
                    Button("Reset") {
                        limiter.percent = defaultPercent
                        limiter.stop()
                        onPercentChange(limiter.percent)
                    }
                    .font(.system(size: 10))
                    .buttonStyle(.borderless)
                    Button(limiter.isRunning ? "Stop" : "Start") {
                        limiter.isRunning ? limiter.stop() : limiter.start()
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .buttonStyle(.borderedProminent)
                    .controlSize(.mini)
                }
            }
        }
        .frame(height: 44)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
    }
}

@main
struct ProcessLeashApp: App {
    var body: some Scene {
        MenuBarExtra("ProcessLeash", systemImage: "gauge") {
            ContentView()
        }
        .menuBarExtraStyle(.window)
    }
}
