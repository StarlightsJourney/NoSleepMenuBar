import SwiftUI
import AppKit

@main
struct NoSleepMenuBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("NoSleep", systemImage: "cup.and.saucer.fill") {
            ContentView()
                .frame(width: 240)
                .environmentObject(SleepManager.shared)
        }
        .menuBarExtraStyle(.window)
    }
}

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.largeTitle)
                .foregroundStyle(.yellow)
            Text("NoSleep is running")
                .font(.headline)
            Text("Look for the coffee cup icon in your menu bar and click it to keep your Mac awake, even with the lid closed. The first use will ask for your password once per session.")
                .font(.callout)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let welcomeKey = "NoSleepWelcomeShown"
    private var welcomePanel: NSPanel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        NSLog("NoSleep launched")
        showWelcomePanelIfNeeded()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Tell the privileged helper to restore the original sleep/display settings.
        // The helper runs as root, so closing its stdin is enough to trigger cleanup.
        SleepManager.shared.terminate()
    }

    private func showWelcomePanelIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: Self.welcomeKey) else { return }

        NSLog("Showing NoSleep welcome panel")

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 180),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.title = "NoSleep"
        panel.contentView = NSHostingView(rootView: WelcomeView())
        panel.isReleasedWhenClosed = false
        panel.center()
        panel.makeKeyAndOrderFront(nil)

        welcomePanel = panel
        UserDefaults.standard.set(true, forKey: Self.welcomeKey)

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            self?.welcomePanel?.close()
            self?.welcomePanel = nil
        }
    }
}
