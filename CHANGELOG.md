# Changelog

## 1.0.1 — 2026-08-01

- Swift 6 language mode (tools 6.0); fixed a concurrency issue in the memory reader.
- Standard repo layout: `scripts/` (build_app, make_icon, release), `Resources/` with versioned Info.plist and committed app icon, `app-manifest.json` for discovery by the MLauncher orchestrator.
- Releases are now distributed as a DMG (`MacStatsOverlay-<version>.dmg`) built by `scripts/release.sh` (previously a zip).
- Standardized About panel shared across the richardogcc utilities fleet.

## 1.0.0 — 2026-07-31

Initial release.

- Glassy translucent overlay panel with live system stats.
- Global hotkey ⌥⌘S and menu bar icon to toggle the overlay.
- Modules: System Info, CPU (per-core), Memory, Storage, Network, Battery, Temperature.
- Settings: toggle each module, refresh interval, per-core bars, launch at login.
- Temperature support for Apple Silicon (IOHID) and Intel (SMC).
- Generated app icon, ad-hoc signed app bundle, build/install script.
