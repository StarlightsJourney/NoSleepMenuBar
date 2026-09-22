# NoSleep

A tiny, free macOS menu-bar utility that keeps your Mac awake with one click.

## What it does

- Lives in your menu bar as a coffee-cup icon.
- Prevents system idle sleep and display sleep.
- Supports closed-lid operation as far as macOS allows.
- Offers preset durations: 5 / 15 / 30 / 60 minutes, or indefinitely.
- Stops automatically when the timer ends, when you click Stop, or when you quit the app.
- The icon turns **yellow** while sleep prevention is active, so you know at a glance that it is running.

## Why I made this

My MacBook's lid sensor is broken, so macOS no longer detects when the lid is closed and the built-in sleep behavior became unreliable. I built NoSleep as a quick, one-click way to keep the Mac awake when I need it and to restore normal sleep settings automatically afterwards.

## Requirements

- macOS 13 or later
- Swift 5.9 toolchain (Xcode or Command Line Tools)

## Build

```bash
./build.sh
```

The script builds the Swift package, bundles the executable into `.build/NoSleep.app`, and ad-hoc signs it.

Copy the app to your Applications folder:

```bash
cp -R .build/NoSleep.app ~/Applications/
```

On first launch you may need to open it via **System Settings → Privacy & Security → Open Anyway** because it is not signed with an Apple Developer ID.

## Tips

### If the menu bar is too crowded

If the coffee-cup icon is hidden by other icons, double-click **NoSleep.app** in Finder while it is already running. It will open a control window so you can still reach the buttons.

For a cleaner menu bar, use a free menu-bar manager such as **[Ice](https://github.com/jordanbaird/Ice)** (open source) or **Hidden Bar** (free on the Mac App Store). They let you hide less important icons while keeping NoSleep visible.

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
