# MacStatsOverlay — project conventions

Shared conventions for the richardogcc macOS utility repos. Follow them for every change.

## Language and license

- Everything in English: README, UI strings, code comments, commit messages.
- License is MIT with exactly `Copyright (c) 2026 richardogcc`.

## Identity

- Bundle ID scheme: `com.richardogcc.<lowercased-app-name>` — here `com.richardogcc.macstatsoverlay`.

## Build

- `Package.swift` uses `// swift-tools-version: 6.0` and platforms `.macOS(.v14)`.
  If Swift 6 language mode ever causes extensive concurrency errors, keep tools 6.0
  and add `swiftSettings: [.swiftLanguageMode(.v5)]` to the target instead of a large refactor.
- `Resources/` holds `Info.plist` (with `__VERSION__` placeholder) and `AppIcon.icns`.
  The app must always ship with an icon; regenerate it with `scripts/make_icon.swift` if missing.

## Versioning

- `VERSION` file at the repo root contains the plain semver version.
- `CHANGELOG.md` follows Keep a Changelog style: one `## <version> — <date>` section per release.
- Bump `VERSION` and add a CHANGELOG entry together for every user-facing release.

## Scripts (`scripts/`, lowercase)

- `build_app.sh` — release build via SwiftPM, assembles the `.app` in `build/`,
  injects `Resources/Info.plist` with the version from `VERSION`, copies `Resources/AppIcon.icns`, signs ad-hoc.
- `make_icon.swift` — generates the app icon PNGs (used to produce `Resources/AppIcon.icns`).
- `release.sh` — builds the app, packages `dist/MacStatsOverlay-<VERSION>.dmg` via `hdiutil`,
  then creates the GitHub release (`gh release create v<VERSION>`) with notes from the CHANGELOG entry.

## Release flow

- Releases are made locally by running `scripts/release.sh` and are pushed manually.
- Claude must never run the `gh release create` step and never push; build/verify up to the DMG only.

## Orchestrator

- `app-manifest.json` at the repo root describes the app (name, bundleId, description, repo,
  minMacOS, artifact pattern) for a future orchestrator app that discovers and installs these utilities.

## Git

- Commits in English, ending with the `Co-Authored-By: Claude ...` trailer.
- Never push; the owner pushes manually.
