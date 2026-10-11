import AppKit
import SwiftUI

/// Owns one clock's desktop window: places it, keeps its aspect ratio in step with
/// the settings, applies locking, and saves its frame when it moves or resizes.
final class ClockWindowController: NSWindowController {
    /// Default on-screen size as a fraction of the clock's design size.
    static let defaultScale: CGFloat = 0.55

    let clockID: UUID
    private let store: ClockStore
    private var saveTask: Task<Void, Never>?

    init(clockID: UUID, store: ClockStore) {
        self.clockID = clockID
        self.store = store
        let config = store.clock(clockID) ?? ClockConfig()
        let window = DesktopWindow(contentRect: Self.initialFrame(for: config))
        super.init(window: window)

        let hostingView = ClockHostingView(rootView: ClockWindowContent(store: store, id: clockID))
        // Let the window, not the SwiftUI content, decide the size.
        hostingView.sizingOptions = []
        window.contentView = hostingView

        NotificationCenter.default.addObserver(
            self, selector: #selector(frameDidChange), name: NSWindow.didMoveNotification, object: window
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(frameDidChange), name: NSWindow.didResizeNotification, object: window
        )

        applyConfig()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    /// Re-applies settings that affect the window rather than the drawing.
    func applyConfig() {
        guard let window, let config = store.clock(clockID) else { return }
        window.ignoresMouseEvents = config.locked

        // Keep the height and match the width to the clock's shape
        // (it changes when seconds are turned on or off).
        let design = ClockLayout(showSeconds: config.showSeconds).size
        window.contentAspectRatio = design
        let frame = window.frame
        let width = frame.height * design.width / design.height
        if abs(width - frame.width) > 0.5 {
            window.setFrame(
                NSRect(x: frame.midX - width / 2, y: frame.minY, width: width, height: frame.height),
                display: true
            )
        }
    }

    /// Returns the clock to its default size, centered on the main screen.
    func resetFrame() {
        guard let window, let config = store.clock(clockID) else { return }
        window.setFrame(Self.defaultFrame(for: config), display: true, animate: true)
    }

    @objc private func frameDidChange(_ notification: Notification) {
        // Moves and resizes arrive many times per second; save once things settle.
        saveTask?.cancel()
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled, let self, let frame = self.window?.frame else { return }
            self.store.update(self.clockID) { $0.frame = frame }
        }
    }

    private static func initialFrame(for config: ClockConfig) -> NSRect {
        // Use the saved frame only if it's still on a connected screen.
        if let saved = config.frame,
           NSScreen.screens.contains(where: { $0.visibleFrame.intersects(saved) }) {
            return saved
        }
        return defaultFrame(for: config)
    }

    private static func defaultFrame(for config: ClockConfig) -> NSRect {
        let design = ClockLayout(showSeconds: config.showSeconds).size
        let size = NSSize(width: design.width * defaultScale, height: design.height * defaultScale)
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        return NSRect(
            origin: NSPoint(x: screen.midX - size.width / 2, y: screen.midY - size.height / 2),
            size: size
        )
    }
}
