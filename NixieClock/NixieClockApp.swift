import SwiftUI

@main
struct NixieClockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Nixie Clock", systemImage: "clock") {
            Button("Quit Nixie Clock") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var clockWindowController: ClockWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = ClockWindowController()
        controller.showWindow(nil)
        clockWindowController = controller
    }
}
