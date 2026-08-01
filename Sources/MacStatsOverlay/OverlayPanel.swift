import AppKit
import SwiftUI

/// Borderless, non-activating floating panel that hosts the SwiftUI overlay.
final class OverlayPanel: NSPanel {
    var onDismiss: (() -> Void)?

    init(rootView: some View) {
        super.init(contentRect: .zero,
                   styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered,
                   defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false           // SwiftUI draws its own shadow
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        isMovableByWindowBackground = true
        hidesOnDeactivate = false
        animationBehavior = .utilityWindow

        let hosting = NSHostingView(rootView: rootView)
        hosting.translatesAutoresizingMaskIntoConstraints = false
        contentView = hosting
    }

    override var canBecomeKey: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            onDismiss?()
        } else {
            super.keyDown(with: event)
        }
    }

    override func cancelOperation(_ sender: Any?) {
        onDismiss?()
    }

    func showCentered() {
        layoutIfNeeded()
        guard let screen = NSScreen.main else { return }
        let size = contentView?.fittingSize ?? frame.size
        setContentSize(size)
        let visible = screen.visibleFrame
        let origin = NSPoint(x: visible.midX - size.width / 2,
                             y: visible.midY - size.height / 2)
        setFrameOrigin(origin)
        makeKeyAndOrderFront(nil)
    }
}
