import AppKit
import SwiftUI

/// A regular window showing the same settings as the menu bar panel.
///
/// It's opened from a clock's right-click menu or by launching the app again,
/// so the settings stay reachable when the menu bar icon is hidden.
final class SettingsWindowController: NSWindowController {
    private static let width: CGFloat = 320
    private static let preferredHeight: CGFloat = 760

    private let manager: ClockManager
    private let hostingController: NSHostingController<SettingsWindowContent>

    init(manager: ClockManager) {
        self.manager = manager
        hostingController = NSHostingController(rootView: SettingsWindowContent(manager: manager))
        // A window that resizes itself to fit the panel loops in AppKit layout and crashes,
        // so the window keeps a fixed size and the panel scrolls inside it.
        hostingController.sizingOptions = []

        let visibleHeight = NSScreen.main?.visibleFrame.height ?? Self.preferredHeight
        let window = NSWindow(contentViewController: hostingController)
        window.title = "Nixie Clock Settings"
        window.styleMask = [.titled, .closable, .resizable]
        window.setContentSize(NSSize(width: Self.width, height: min(Self.preferredHeight, visibleHeight - 40)))
        window.contentMinSize = NSSize(width: Self.width, height: 300)
        window.contentMaxSize = NSSize(width: Self.width, height: .greatestFiniteMagnitude)
        window.isReleasedWhenClosed = false
        super.init(window: window)
        window.center()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    /// Brings the window forward, optionally with one clock selected.
    func show(selecting clockID: UUID? = nil) {
        if let clockID {
            hostingController.rootView = SettingsWindowContent(manager: manager, selectedID: clockID)
        }
        // The app has no Dock icon, so it must activate itself for the window to come forward.
        NSApp.activate()
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
    }
}

/// The menu bar panel, scrollable so it fits a fixed-size window.
struct SettingsWindowContent: View {
    let manager: ClockManager
    var selectedID: UUID?

    var body: some View {
        ScrollView {
            MenuPanelView(manager: manager, selectedID: selectedID)
                // Fresh selection state when a different clock is chosen from its right-click menu.
                .id(selectedID)
        }
    }
}
