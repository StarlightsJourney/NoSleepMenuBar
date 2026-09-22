import Foundation
import AppKit
import AuthHelper

final class SleepManager: ObservableObject {
    static let shared = SleepManager()

    @Published private(set) var isPreventingSleep = false
    @Published private(set) var isBusy = false
    @Published private(set) var remainingSeconds: Int?
    @Published private(set) var lastError: String?

    private var timer: Timer?
    private var helperStdin: FileHandle?
    private var originalSettings: (disablesleep: String, displaysleep: String)?

    private init() {}

    func start(duration: TimeInterval? = nil) {
        guard !isPreventingSleep && !isBusy else { return }
        lastError = nil
        originalSettings = readCurrentPowerSettings()
        isBusy = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            let success = self.launchHelper(duration: duration)
            DispatchQueue.main.async {
                self.isBusy = false
                if success {
                    self.isPreventingSleep = true
                    if let duration = duration {
                        let seconds = Int(duration)
                        self.remainingSeconds = seconds
                        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                            guard let self else { return }
                            self.remainingSeconds = max(0, (self.remainingSeconds ?? 0) - 1)
                            if self.remainingSeconds == 0 {
                                self.timer?.invalidate()
                                self.timer = nil
                                self.isPreventingSleep = false
                                self.remainingSeconds = nil
                                self.helperStdin = nil
                                self.originalSettings = nil
                            }
                        }
                    }
                } else {
                    self.lastError = "Could not start helper. Check Console for 'NoSleep:' logs."
                    self.helperStdin = nil
                    self.originalSettings = nil
                }
            }
        }
    }

    func stop() {
        guard isPreventingSleep else { return }
        sendRestoreAndClose()
        resetState()
    }

    /// Called from `applicationWillTerminate` to ask the helper to restore settings.
    func terminate() {
        helperStdin?.closeFile()
        helperStdin = nil
        resetState()
    }

    private func resetState() {
        timer?.invalidate()
        timer = nil
        isPreventingSleep = false
        remainingSeconds = nil
        originalSettings = nil
    }

    private func sendRestoreAndClose() {
        if let handle = helperStdin {
            if let data = "RESTORE\n".data(using: .utf8) {
                handle.write(data)
            }
            handle.closeFile()
        }
        helperStdin = nil
    }

    private func launchHelper(duration: TimeInterval?) -> Bool {
        DispatchQueue.main.sync {
            NSApp.activate(ignoringOtherApps: true)
        }

        guard let helperPath = helperExecutablePath() else {
            NSLog("NoSleep: could not find helper executable")
            return false
        }

        let settings = originalSettings ?? (disablesleep: "0", displaysleep: "10")
        var arguments: [String] = [helperPath, settings.disablesleep, settings.displaysleep]
        if let duration = duration {
            arguments.append(String(Int(duration)))
        }

        NSLog("NoSleep: launching helper at %@ with args %@", helperPath, arguments)

        let cArguments: [UnsafeMutablePointer<CChar>?] = arguments.map { strdup($0) } + [nil]
        let launch = cArguments.withUnsafeBufferPointer { buffer -> AuthHelperLaunch in
            guard let baseAddress = buffer.baseAddress else {
                return AuthHelperLaunch(success: 0, stdin_fd: -1, pid: -1)
            }
            return helperPath.withCString { path in
                auth_helper_launch(path, baseAddress)
            }
        }
        for ptr in cArguments.dropLast() {
            free(ptr)
        }

        if launch.success != 0 && launch.stdin_fd >= 0 {
            NSLog("NoSleep: helper launched, stdin_fd=%d", launch.stdin_fd)
            helperStdin = FileHandle(fileDescriptor: launch.stdin_fd, closeOnDealloc: true)
            return true
        }

        NSLog("NoSleep: helper launch failed (success=%d, fd=%d)", launch.success, launch.stdin_fd)
        return false
    }

    private func helperExecutablePath() -> String? {
        let helperURL = Bundle.main.bundleURL
            .appendingPathComponent("Contents")
            .appendingPathComponent("Helpers")
            .appendingPathComponent("NoSleepHelper")
        return helperURL.path
    }

    private func readCurrentPowerSettings() -> (disablesleep: String, displaysleep: String) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        task.arguments = ["-g"]
        let pipe = Pipe()
        task.standardOutput = pipe

        var disablesleep = "0"
        var displaysleep = "10"

        do {
            try task.run()
            task.waitUntilExit()
            let output = String(
                data: pipe.fileHandleForReading.readDataToEndOfFile(),
                encoding: .utf8
            ) ?? ""
            for line in output.split(separator: "\n") {
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                let parts = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                guard parts.count >= 2 else { continue }
                let value = parts[1]
                switch parts[0] {
                case "SleepDisabled", "disablesleep":
                    disablesleep = value
                case "displaysleep":
                    displaysleep = value
                default:
                    break
                }
            }
        } catch {
            // Fall through to safe defaults.
        }

        return (disablesleep: disablesleep, displaysleep: displaysleep)
    }
}
