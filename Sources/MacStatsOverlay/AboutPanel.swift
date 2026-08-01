import AppKit

/// About card: app icon, name, version and license. Any click dismisses it.
/// Mirrors the standardized About pattern shared across the richardogcc utilities.
final class AboutCardView: NSVisualEffectView {
    var onDismiss: (() -> Void)?

    init() {
        super.init(frame: .zero)
        material = .hudWindow
        blendingMode = .behindWindow
        state = .active
        wantsLayer = true
        layer?.cornerRadius = 14
        layer?.masksToBounds = true

        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
            as? String ?? "dev"

        let icon = NSImageView(image: NSApp.applicationIconImage ?? NSImage())
        icon.frame = NSRect(x: 0, y: 0, width: 72, height: 72)

        let lines: [(String, NSFont, NSColor)] = [
            ("Mac Stats Overlay", .systemFont(ofSize: 20, weight: .bold), .labelColor),
            ("Version \(version)", .systemFont(ofSize: 12), .secondaryLabelColor),
            ("Glassy system stats overlay for macOS",
             .systemFont(ofSize: 12), .secondaryLabelColor),
            ("github.com/richardogcc/MacStatsOverlay  ·  MIT License",
             .systemFont(ofSize: 11), .tertiaryLabelColor),
        ]
        let labels: [NSTextField] = lines.map { text, font, color in
            let label = NSTextField(labelWithString: text)
            label.font = font
            label.textColor = color
            label.alignment = .center
            label.sizeToFit()
            return label
        }

        let padding: CGFloat = 32
        let spacing: CGFloat = 8
        let contentWidth = max(labels.map { $0.frame.width }.max() ?? 0, 220)
        let textHeight = labels.reduce(0) { $0 + $1.frame.height } +
            spacing * CGFloat(labels.count - 1)
        let width = contentWidth + padding * 2
        let height = padding + icon.frame.height + 14 + textHeight + padding
        frame = NSRect(x: 0, y: 0, width: width, height: height)

        icon.setFrameOrigin(NSPoint(x: (width - icon.frame.width) / 2,
                                    y: height - padding - icon.frame.height))
        var y = height - padding - icon.frame.height - 14
        for label in labels {
            y -= label.frame.height
            label.frame = NSRect(x: padding, y: y, width: contentWidth,
                                 height: label.frame.height)
            addSubview(label)
            y -= spacing
        }
        addSubview(icon)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func mouseDown(with event: NSEvent) {
        onDismiss?()
    }
}

/// Small floating borderless panel that shows the About card centered on screen.
/// Click on the card or Escape closes it.
final class AboutPanel: NSPanel {
    init() {
        let card = AboutCardView()
        super.init(contentRect: card.frame,
                   styleMask: [.borderless],
                   backing: .buffered,
                   defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        isMovableByWindowBackground = true
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        animationBehavior = .utilityWindow

        card.onDismiss = { [weak self] in self?.close() }
        contentView = card
    }

    override var canBecomeKey: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            close()
        } else {
            super.keyDown(with: event)
        }
    }

    override func cancelOperation(_ sender: Any?) {
        close()
    }

    func showCentered() {
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        setFrameOrigin(NSPoint(x: visible.midX - frame.width / 2,
                               y: visible.midY - frame.height / 2))
        NSApp.activate(ignoringOtherApps: true)
        makeKeyAndOrderFront(nil)
    }
}
