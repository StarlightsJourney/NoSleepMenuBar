import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var sleepManager: SleepManager

    private let timeFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: sleepManager.isPreventingSleep ? "cup.and.saucer.fill" : "cup.and.saucer")
                    .foregroundStyle(sleepManager.isPreventingSleep ? .yellow : .secondary)
                Text(sleepManager.isPreventingSleep ? "Sleep disabled" : "Sleep enabled")
                    .font(.headline)
                Spacer()
            }

            if sleepManager.isPreventingSleep {
                Text("Your Mac and display will not sleep until you stop this. It may get warm and drain battery quickly, especially with the lid closed.")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let remaining = sleepManager.remainingSeconds, remaining > 0 {
                Text(timeFormatter.string(from: TimeInterval(remaining)) ?? "")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let error = sleepManager.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Button("Indefinitely") { sleepManager.start() }
                Button("5 minutes") { sleepManager.start(duration: 5 * 60) }
                Button("15 minutes") { sleepManager.start(duration: 15 * 60) }
                Button("30 minutes") { sleepManager.start(duration: 30 * 60) }
                Button("1 hour") { sleepManager.start(duration: 60 * 60) }
            }
            .disabled(sleepManager.isPreventingSleep || sleepManager.isBusy)

            Divider()

            Button(sleepManager.isPreventingSleep ? "Stop preventing sleep" : "Prevent sleep now") {
                if sleepManager.isPreventingSleep {
                    sleepManager.stop()
                } else {
                    sleepManager.start()
                }
            }
            .disabled(sleepManager.isBusy)

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .disabled(sleepManager.isBusy)
        }
        .padding()
    }
}
