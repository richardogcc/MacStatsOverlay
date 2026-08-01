import AppKit
import SwiftUI
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let engine = StatsEngine()
    private let preferences = Preferences.shared

    private var statusItem: NSStatusItem!
    private var hotKey: HotKeyManager?
    private var overlayPanel: OverlayPanel?
    private var settingsWindow: NSWindow?
    private var aboutPanel: AboutPanel?
    private var clickMonitor: Any?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "gauge.with.needle",
                                accessibilityDescription: "Mac Stats Overlay")
            image?.isTemplate = true
            button.image = image
            button.target = self
            button.action = #selector(statusItemClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        hotKey = HotKeyManager { [weak self] in
            Task { @MainActor in self?.toggleOverlay() }
        }

        // Restart the timer when the refresh interval changes while the overlay is open.
        preferences.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self, self.engine.isRunning else { return }
                self.engine.start(interval: self.preferences.refreshInterval)
            }
            .store(in: &cancellables)
    }

    // MARK: - Status item

    @objc private func statusItemClicked() {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp || event.modifierFlags.contains(.control) {
            showMenu()
        } else {
            toggleOverlay()
        }
    }

    private func showMenu() {
        let menu = NSMenu()
        let toggleItem = NSMenuItem(title: overlayPanel == nil ? "Show Overlay" : "Hide Overlay",
                                    action: #selector(toggleOverlayFromMenu), keyEquivalent: "s")
        toggleItem.keyEquivalentModifierMask = [.command, .option]
        toggleItem.target = self
        menu.addItem(toggleItem)
        menu.addItem(.separator())

        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let aboutItem = NSMenuItem(title: "About Mac Stats Overlay",
                                   action: #selector(openAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil   // detach so left-click keeps toggling the overlay
    }

    @objc private func toggleOverlayFromMenu() {
        toggleOverlay()
    }

    // MARK: - Overlay

    func toggleOverlay() {
        if overlayPanel != nil {
            hideOverlay()
        } else {
            showOverlay()
        }
    }

    private func showOverlay() {
        engine.start(interval: preferences.refreshInterval)

        let panel = OverlayPanel(rootView: OverlayView(engine: engine, preferences: preferences))
        panel.onDismiss = { [weak self] in self?.hideOverlay() }
        overlayPanel = panel
        panel.showCentered()

        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor in self?.hideOverlay() }
        }
    }

    private func hideOverlay() {
        engine.stop()
        if let clickMonitor {
            NSEvent.removeMonitor(clickMonitor)
            self.clickMonitor = nil
        }
        overlayPanel?.orderOut(nil)
        overlayPanel = nil
    }

    // MARK: - Settings & About

    @objc private func openSettings() {
        if settingsWindow == nil {
            let window = NSWindow(contentRect: .zero,
                                  styleMask: [.titled, .closable],
                                  backing: .buffered,
                                  defer: false)
            window.title = "Mac Stats Overlay Settings"
            window.contentView = NSHostingView(rootView: SettingsView(preferences: preferences))
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    @objc private func openAbout() {
        if aboutPanel == nil {
            aboutPanel = AboutPanel()
        }
        aboutPanel?.showCentered()
    }
}
