import AppKit

/// A borderless, transparent window that sits on the desktop: above the wallpaper
/// and desktop icons, below every normal app window, on every Space — or, when
/// kept on top, above every app window.
///
/// Moving and resizing are handled by `ClockHostingView`, so the window itself
/// has no resizable style and no background dragging.
final class DesktopWindow: NSWindow {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isReleasedWhenClosed = false

        setKeepsOnTop(false)
    }

    /// Floats the window above every app window (including full-screen apps),
    /// or returns it to the desktop layer.
    func setKeepsOnTop(_ onTop: Bool) {
        if onTop {
            level = .floating
            collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        } else {
            level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
            collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenNone]
        }
    }

    // Borderless windows can't become key by default; allowing it lets the
    // window take drags and, later, keyboard input.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
