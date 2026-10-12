import SwiftUI

@main
struct NixieClockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Nixie Clock", systemImage: "clock") {
            MenuPanelView(manager: appDelegate.manager)
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let manager = ClockManager(store: ClockStore())

    func applicationDidFinishLaunching(_ notification: Notification) {
        NixieFonts.register()
        manager.openAllWindows()
    }

    /// Launching the app again while it's running opens the settings window.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        manager.showSettings()
        return false
    }
}
