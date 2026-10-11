import AppKit

/// A borderless, transparent window that sits on the desktop: above the wallpaper
/// and desktop icons, below every normal app window, on every Space.
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

        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenNone]
    }

    // Borderless windows can't become key by default; allowing it lets the
    // window take drags and, later, keyboard input.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
