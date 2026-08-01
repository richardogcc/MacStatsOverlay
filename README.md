# Mac Stats Overlay

A native macOS menu bar app that shows a glassy, translucent overlay with live system stats — toggled with a global hotkey or a click on the menu bar icon.

![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-blue)
![Swift](https://img.shields.io/badge/Swift-6.0-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Glassy overlay** — borderless, translucent (ultra-thin material) floating panel with rounded corners, shown on top of everything without stealing focus.
- **Global hotkey** — toggle the overlay from anywhere with **⌥⌘S** (no accessibility permissions needed).
- **Menu bar icon** — left-click toggles the overlay; right-click opens the menu (Settings, About, Quit).
- **Live stats modules**:
  - **System Info** — model, chip, macOS version, uptime
  - **CPU** — total usage, per-core bars, load averages
  - **Memory** — used/total, wired and compressed breakdown
  - **Storage** — free/total space on the boot volume
  - **Network** — live download/upload speed, local IP
  - **Battery** — level, charging state, time remaining, cycle count
  - **Temperature** — CPU temperature (Apple Silicon via IOHID sensors, Intel via SMC)
- **Configurable** — every module can be toggled on/off in Settings, plus refresh interval (1/2/5 s), per-core bars, and launch at login.
- **Lightweight** — stats are only sampled while the overlay is visible.

## Install

Download the latest `MacStatsOverlay-X.Y.Z.dmg` from [Releases](https://github.com/richardogcc/MacStatsOverlay/releases), open it, and drag `MacStatsOverlay.app` into `/Applications`.

> The app is ad-hoc signed. On first launch, right-click the app → **Open** to bypass Gatekeeper.

## Usage

| Action | How |
|---|---|
| Toggle overlay | **⌥⌘S** or left-click the menu bar gauge icon |
| Close overlay | **Esc** or click anywhere outside |
| Settings | Right-click the menu bar icon → **Settings…** |
| Quit | Right-click the menu bar icon → **Quit** |

## Build from source

Requires Xcode 16+ / Swift 6.0+ on macOS 14+.

```sh
git clone https://github.com/richardogcc/MacStatsOverlay.git
cd MacStatsOverlay
scripts/build_app.sh            # builds build/MacStatsOverlay.app
scripts/build_app.sh --install  # also installs to /Applications and launches it
scripts/release.sh              # packages dist/MacStatsOverlay-<version>.dmg and publishes a GitHub release
```

## How it works

- **CPU** — `host_processor_info` tick deltas per core.
- **Memory** — `host_statistics64` (app + wired + compressed, like Activity Monitor).
- **Storage** — `URLResourceValues` with APFS-aware important-usage capacity.
- **Network** — `getifaddrs` byte counters on `en*` interfaces, sampled into per-second rates.
- **Battery** — `IOPSCopyPowerSourcesInfo` + `AppleSmartBattery` cycle count.
- **Temperature** — `IOHIDEventSystemClient` temperature events on Apple Silicon; `AppleSMC` key reads on Intel.
- **Hotkey** — Carbon `RegisterEventHotKey` (works without accessibility permissions).

## License

[MIT](LICENSE)
