import AppKit
import SwiftUI

/// Owns one clock's desktop window and hosts its SwiftUI view.
final class ClockWindowController: NSWindowController {
    static let defaultSize = NSSize(width: 520, height: 180)

    convenience init() {
        let size = Self.defaultSize
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let origin = NSPoint(x: screen.midX - size.width / 2, y: screen.midY - size.height / 2)
        let window = DesktopWindow(contentRect: NSRect(origin: origin, size: size))

        let hostingView = NSHostingView(rootView: NixieClockView())
        // Let the window, not the SwiftUI content, decide the size.
        hostingView.sizingOptions = []
        window.contentView = hostingView
        window.contentAspectRatio = size

        self.init(window: window)
    }
}
