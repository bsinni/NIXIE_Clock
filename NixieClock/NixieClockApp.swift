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
        manager.openAllWindows()
    }
}
