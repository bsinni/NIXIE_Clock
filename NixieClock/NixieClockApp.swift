import SwiftUI

@main
struct NixieClockApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Nixie Clock", systemImage: "clock") {
            Toggle("Lock Clock Position", isOn: Binding(
                get: { appDelegate.allLocked },
                set: { appDelegate.setAllLocked($0) }
            ))
            Button("Reset Size and Position") {
                appDelegate.resetFrames()
            }
            Divider()
            Button("Quit Nixie Clock") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let store = ClockStore()
    private var windowControllers: [UUID: ClockWindowController] = [:]

    func applicationDidFinishLaunching(_ notification: Notification) {
        for clock in store.clocks {
            let controller = ClockWindowController(clockID: clock.id, store: store)
            controller.showWindow(nil)
            windowControllers[clock.id] = controller
        }
    }

    var allLocked: Bool {
        !store.clocks.isEmpty && store.clocks.allSatisfy(\.locked)
    }

    /// Locks or unlocks every clock. Locked clocks let clicks pass through to the desktop.
    func setAllLocked(_ locked: Bool) {
        for clock in store.clocks {
            store.update(clock.id) { $0.locked = locked }
        }
        windowControllers.values.forEach { $0.applyConfig() }
    }

    func resetFrames() {
        windowControllers.values.forEach { $0.resetFrame() }
    }
}
