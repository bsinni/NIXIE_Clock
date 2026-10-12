import AppKit

/// Drives the system color panel for the "Custom…" buttons.
///
/// The menu bar panel closes as soon as the color panel takes focus, so the
/// color panel reports to this long-lived object instead of to a SwiftUI view.
final class ColorPanelCoordinator: NSObject {
    private var onChange: ((NSColor) -> Void)?

    func show(initial: NSColor, showsAlpha: Bool, onChange: @escaping (NSColor) -> Void) {
        let panel = NSColorPanel.shared
        // Detach first so setting the starting color doesn't fire the previous handler.
        panel.setTarget(nil)
        panel.setAction(nil)
        panel.showsAlpha = showsAlpha
        panel.isContinuous = true
        panel.color = initial

        self.onChange = onChange
        panel.setTarget(self)
        panel.setAction(#selector(colorDidChange(_:)))

        NSApp.activate()
        panel.makeKeyAndOrderFront(nil)
    }

    @objc private func colorDidChange(_ sender: NSColorPanel) {
        onChange?(sender.color)
    }
}
