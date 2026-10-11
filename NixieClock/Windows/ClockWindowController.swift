import AppKit
import SwiftUI

/// Owns one clock's desktop window and hosts its SwiftUI view.
final class ClockWindowController: NSWindowController {
    /// Default on-screen size as a fraction of the clock's design size.
    static let defaultScale: CGFloat = 0.55

    convenience init(config: ClockConfig = ClockConfig()) {
        let design = ClockLayout(showSeconds: config.showSeconds).size
        let size = NSSize(width: design.width * Self.defaultScale, height: design.height * Self.defaultScale)
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let origin = NSPoint(x: screen.midX - size.width / 2, y: screen.midY - size.height / 2)
        let window = DesktopWindow(contentRect: NSRect(origin: origin, size: size))

        let hostingView = NSHostingView(rootView: NixieClockView(config: config))
        // Let the window, not the SwiftUI content, decide the size.
        hostingView.sizingOptions = []
        window.contentView = hostingView
        window.contentAspectRatio = design

        self.init(window: window)
    }
}
