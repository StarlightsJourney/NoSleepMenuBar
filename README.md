# NoSleep

A tiny, free macOS menu-bar utility that keeps your Mac awake with one click.

## What it does

- Lives in your menu bar as a coffee-cup icon.
- Prevents system idle sleep and display sleep.
- Supports closed-lid operation as far as macOS allows.
- Offers preset durations: 5 / 15 / 30 / 60 minutes, or indefinitely.
- Stops automatically when the timer ends, when you click Stop, or when you quit the app.

## Requirements

- macOS 13 or later
- Swift 5.9 toolchain (Xcode or Command Line Tools)

## Build

```bash
./build.sh
```

The script builds the Swift package, bundles the executable into `NoSleep.app`, and ad-hoc signs it.

Copy the app to your Applications folder:

```bash
cp -R NoSleep.app ~/Applications/
```

On first launch you may need to open it via **System Settings → Privacy & Security → Open Anyway** because it is not signed with an Apple Developer ID.

## How it works

NoSleep uses macOS's own `/usr/bin/pmset` command to temporarily disable system sleep and display sleep. Because changing those settings requires administrator privileges, a small helper executable (`NoSleepHelper`) is bundled inside the app and launched with root privileges through the standard macOS authentication dialog. The helper restores your original power settings when the timer expires, when you stop the app, or when the app quits.

## Security & privacy

- **No network access.** The app does not make any network connections.
- **No data collection.** No analytics, telemetry, tracking, or user content is collected.
- **No secrets.** No API keys, tokens, passwords, or personal identifiers are stored in the source code.
- **Your password is handled by macOS.** The app never reads or stores your password; it only asks macOS to run its helper with administrator privileges.
- **Open source.** All source files are in this repository.

## Warnings

- Preventing sleep (especially with the lid closed) can drain the battery and cause the Mac to get warm. Use the shortest timer you need.
- macOS, hardware thermal protection, low battery, or clamshell-mode requirements may still force sleep even when sleep is disabled.

## License

MIT License — see [LICENSE](LICENSE).
