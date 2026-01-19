// Copyright (C) 2026 ProcessLeash contributors
// Licensed under the GNU General Public License v3.0

import Foundation
import Darwin

@MainActor
final class CPULimiter: ObservableObject {
    let pid: pid_t

    @Published var percent: Double
    @Published private(set) var isRunning: Bool = false

    /// Refresh period for priority adjustments (no STOP/CONT).
    var periodMs: Double = 300

    private var task: Task<Void, Never>?

    init(pid: pid_t, percent: Double) {
        self.pid = pid
        self.percent = min(100, max(0, percent))
    }

    private func niceValue(for percent: Double) -> Int32 {
        if percent >= 99 { return 0 } // без ограничений
        let clamped = min(100, max(0, percent))
        // 0% -> nice 19, 100% -> nice 0
        let mapped = Int32(round((100 - clamped) / 100.0 * 19.0))
        return max(0, min(19, mapped))
    }

    func start() {
        guard task == nil else { return }
        isRunning = true

        let pid = self.pid

        task = Task(priority: .background) { [weak self] in
            guard let self else { return }

            func pidExists(_ pid: pid_t) -> Bool {
                if kill(pid, 0) == 0 { return true }
                return errno != ESRCH
            }

            while !Task.isCancelled, pidExists(pid) {
                let nice = self.niceValue(for: self.percent)
                _ = setpriority(PRIO_PROCESS, UInt32(pid), nice)
                try? await Task.sleep(nanoseconds: UInt64(self.periodMs * 1_000_000))
            }

            // Reset priority when exiting
            _ = setpriority(PRIO_PROCESS, UInt32(pid), 0)
            self.isRunning = false
            self.task = nil
        }
    }

    func stop() {
        task?.cancel()
        task = nil
        _ = setpriority(PRIO_PROCESS, UInt32(pid), 0)   // ensure default priority on stop
        isRunning = false
    }

    deinit {
        Task { @MainActor [weak self] in
            self?.stop()
        }
    }
}
